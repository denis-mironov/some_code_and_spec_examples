# frozen_string_literal: true

# This service is used to return the suggested realtor contact for the given zip code and face_type:
#  'supply' - before Instruction stage (supply realtor contact)
#  'demand' - after Instruction stage (demand realtor contact)
class SelectRealtorContactService
  attr_reader :zip_code, :face_type, :with_other_contacts, :selection_context

  ALLOWABLE_FACE_TYPES = %w[supply demand].freeze

  def initialize(zip_code, face_type, with_other_contacts: false)
    @zip_code = zip_code
    @face_type = face_type
    @with_other_contacts = with_other_contacts
    @selection_context = {}
  end

  def call
    return error_response('Invalid face type') unless face_type_valid?

    validate_zip_code
    select_realtor_contacts
  rescue StandardError => e
    ErrorTracker.notify(e)
    error_response(e.message)
  end

  private

  def select_realtor_contacts
    return success_response(nil) if realtor_contact_zip_codes.empty?

    available_contacts = valid_realtor_contacts
    suggested_contact = suggested_realtor_contact(available_contacts)

    prepare_response(suggested_contact, available_contacts)
  end

  def realtor_contact_zip_codes
    @realtor_contact_zip_codes ||= RealtorContactZipCode.where(zip_code: zip_code, face_type: face_type)
  end

  # validation for the realtor_model takes place during the realtor_contact_zip_codes creation
  def valid_realtor_contacts
    realtor_contact_zip_codes.map do |realtor_contact_zip_code|
      realtor_contact = realtor_contact_zip_code.realtor_contact

      next unless realtor_contact.realtor.company_realtor?
      next unless realtor_contact.assign_new_leads?
      next if realtor_contact.blacklisted?

      realtor_contact
    end
  end

  # selects the realtor contact based on round robin until
  # personal monthly target is reached for all realtor contacts
  # otherwise will select realtor contact with the least number of assigned deals
  def suggested_realtor_contact(available_contacts)
    return unless available_contacts.compact.any?

    least_deals_strategy = available_contacts.compact.all? { |contact| threshold_reached_for?(contact) }

    if least_deals_strategy
      fill_selection_context(:least_deals_strategy, available_contacts)
      available_contacts.compact.min_by { |contact| assignments_count_for(contact) }
    else
      threshold_not_reached_contacts = available_contacts.reject do |contact|
        threshold_reached_for?(contact)
      end
      fill_selection_context(:round_robin_strategy, threshold_not_reached_contacts)
      QualifiedLeadAssignmentCount.next_round_robin_contact(threshold_not_reached_contacts)
    end
  end

  def fill_selection_context(strategy, realtor_contacts)
    @selection_context = { strategy: strategy }
    realtor_contacts.each_with_index do |contact, index|
      selection_context[:"realtor_#{index}"] = {
        realtor_contact_uid: contact.uid,
        assignment_count: assignments_count_for(contact),
        month: Date.current.month,
        year: Date.current.year
      }
    end
  end

  def threshold_reached_for?(contact)
    QualifiedLeadAssignmentCount.threshold_reached?(contact)
  end

  def assignments_count_for(contact)
    QualifiedLeadAssignmentCount.assignments_count(contact)
  end

  def prepare_response(suggested_contact, available_contacts)
    if with_other_contacts
      other_contacts = available_contacts.without(suggested_contact)
      success_response(suggested_contact, other_contacts)
    else
      success_response(suggested_contact)
    end
  end

  def face_type_valid?
    ALLOWABLE_FACE_TYPES.include?(face_type)
  end

  def validate_zip_code
    ZipCode.find_by!(zip_code: zip_code)
  end

  def success_response(suggested_contact, other_contacts = [])
    {
      success: true,
      realtor_contact: suggested_contact,
      other_contacts: other_contacts,
      selection_context: selection_context
    }
  end

  def error_response(error_message)
    {
      success: false,
      realtor_contact: nil,
      other_contacts: [],
      selection_context: selection_context,
      error: error_message
    }
  end
end
