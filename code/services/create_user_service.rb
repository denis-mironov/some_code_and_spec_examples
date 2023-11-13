# frozen_string_literal: true

# This service is used to create (in rare cases update) customer_user and to set a password for them on the backend.
# A customer_user created in this way can be identified by 'created_with_evaluation: true' field.

class Customer::Sellers::CreateUserService
  attr_reader :person, :customer_user

  EMAIL_ALREADY_REGISTERED_ERROR = 'email_already_registered'
  CREATION_FAILED_ERROR = 'creation_failed'
  UPDATE_FAILED_ERROR = 'update_failed'

  def initialize(person)
    @person = person
    @customer_user = person.customer_user
  end

  def call
    customer_user.present? ? handle_existing_customer_user : create_new_customer_user
  end

  private

  def handle_existing_customer_user
    reactivate_an_account if customer_user.deactivated_or_deleted?
    return user_with_default_password if customer_user.guest?

    success_response(account_already_confirmed: true)
  end

  def reactivate_an_account
    Customer::Sellers::ReactivateUserAccountService.new(customer_user).call
  end

  # When customer_user is a guest, this means that the user has never confirmed their account and
  # has never used our app before. In this case, we consider such a user as a newly created one
  # and set the default password for them.
  def user_with_default_password
    ActiveRecord::Base.transaction do
      set_default_password unless customer_user.password_set?
      customer_user.update!(uses_default_password: true)
    end

    success_response
  rescue StandardError => e
    Rails.logger.error("Customer user (uid: #{customer_user.uid}) update errors: #{e.inspect}")
    error_response(UPDATE_FAILED_ERROR)
  end

  def create_new_customer_user
    if person.email_taken_for_another_customer_user_account?
      track_failed_account_creation
      error_response(EMAIL_ALREADY_REGISTERED_ERROR)
    else
      create_customer_user
      return error_response(CREATION_FAILED_ERROR) unless customer_user.present? && customer_user.valid?

      success_response
    end
  end

  def track_failed_account_creation
    TimestreamTrackerService.new.track(
      measure_name: :event,
      measure_value: :account_for_customer_email_already_exists,
      tags: [
        {
          name: :feature,
          value: :customer_invitation
        }
      ]
    )
  end

  def create_customer_user
    ActiveRecord::Base.transaction do
      @customer_user = invite_customer_user
      set_default_password
      update_related_fields
    end
  rescue StandardError => e
    Rails.logger.error("Customer user creation error: #{e.inspect}")
    @customer_user = nil
  end

  def invite_customer_user
    Customer::User.invite!(
      {
        email: person.primary_email_address_email,
        person_id: person.id,
        skip_invitation: true
      }
    )
  end

  def set_default_password
    password = SecureRandom.hex
    customer_user.update!(password: password, password_confirmation: password)
  end

  def update_related_fields
    customer_user.update!(
      created_with_evaluation: true,
      uses_default_password: true
    )
  end

  def success_response(account_already_confirmed: false)
    { success: true, customer_user: customer_user, account_already_confirmed: account_already_confirmed }
  end

  def error_response(error)
    error_message = case error
                    when 'email_already_registered'
                      I18n.t('person' + '.' + error)
                    else
                      I18n.t('errors.messages.customer_user' + '.' + error)
                    end

    { success: false, message: error_message }
  end
end
