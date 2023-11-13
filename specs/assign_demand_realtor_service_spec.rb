# frozen_string_literal: true

shared_examples 'creates demand deal_assignment' do
  it 'creates demand deal_assignment' do
    expect { service_call }.to change(
      DealAssignment.where(
        state: 'active',
        role: 'demand',
        deal_id: deal.id,
        realtor_contact_id: realtor_contact.id
      ), :count
    ).by(1)
  end
end

shared_examples 'logs an error' do
  it 'logs an error' do
    service_call

    expect(Rails.logger).to have_received(:error).with(log_message)
  end
end

shared_examples 'calls ErrorTracker' do
  it 'calls ErrorTracker' do
    service_call

    expect(ErrorTracker).to have_received(:notify)
  end
end

shared_examples 'deactives supply deal assignments' do
  it 'deactives supply deal assignments' do
    expect { service_call }.to change(
      DealAssignment.where(
        state: 'inactive',
        role: 'supply'
      ), :count
    ).by(1)
  end
end

shared_examples 'doesn\'t send confirmation email' do
  it 'doesn\'t send confirmation email' do
    service_call

    expect(MandrillMailWorker).not_to have_received(:perform_async)
  end
end

shared_examples 'doesn\'t create SwitchContact log entry' do
  it 'doesn\'t create SwitchContact log entry' do
    expect { service_call }.not_to change { Log.where(action: 'SwitchedContact').count }
  end
end

RSpec.describe AssignDemandRealtorService do
  subject(:service_call) { described_class.new(deal).call }

  let(:property) { create(:property) }
  let(:zip_code) { property.zip_code }
  let(:supply_realtor) { create(:realtor, :company_realtor) }
  let(:supply_realtor_contact) do
    create(:realtor_contact, :with_crm_user, contactable: supply_realtor, realtor_model: 'supply')
  end
  let(:deal) { create(:deal, property: property, realtor_contact: supply_realtor_contact, realtor: supply_realtor) }
  let!(:supply_assignment) { create(:deal_assignment, :supply, deal: deal, realtor_contact: supply_realtor_contact) }
  let(:area_manager) { create(:crm_user) }
  let(:success_response) do
    {
      success: true
    }
  end
  let(:error_response) do
    {
      success: false,
      error: error_message
    }
  end

  before do
    create(:managed_zip_code, :two_face, zip_code: zip_code, crm_user_id: area_manager.id)
    allow(MandrillMailWorker).to receive(:perform_async)
  end

  context 'when demand realtor is already assigned to a deal' do
    let!(:demand_assignment) { create(:deal_assignment, :demand, :active, deal: deal) }

    include_examples 'doesn\'t send confirmation email'
    include_examples 'doesn\'t create SwitchContact log entry'

    it { expect { service_call }.not_to change(demand_assignment, :reload) }
    it { expect { service_call }.not_to change(DealAssignment, :count) }
    it { expect(service_call).to match(success_response) }
  end

  context 'when managed zip code is not found' do
    let(:error_message) { /Couldn't find ManagedZipCode/ }

    before do
      ManagedZipCode.destroy_all
      allow(ErrorTracker).to receive(:notify)
    end

    include_examples 'calls ErrorTracker'

    it { expect(service_call).to match(error_response) }
  end

  context 'when managed zip code belongs to 1 Face model' do
    before { ManagedZipCode.find_by!(zip_code: zip_code).one_face! }

    include_examples 'creates demand deal_assignment' do
      let(:realtor_contact) { supply_realtor_contact }
    end

    include_examples 'deactives supply deal assignments'
    include_examples 'doesn\'t send confirmation email'
    include_examples 'doesn\'t create SwitchContact log entry'
  end

  context 'when managed zip code belongs to 2 Face model' do
    let(:mailer_class) { described_class::MANDRILL_MAILER_CLASS }
    let(:mail_object_type) { described_class::MAIL_OBJECT_TYPE }
    let(:contacts_service) { SelectRealtorContactService }
    let(:service_instance) { instance_double(contacts_service, call: contacts_response) }
    let(:demand_realtor) { create(:realtor, :company_realtor) }
    let(:demand_realtor_contact) { create(:realtor_contact, :with_crm_user, contactable: demand_realtor) }
    let(:contacts_response) do
      {
        success: true,
        realtor_contact: demand_realtor_contact,
        other_contacts: []
      }
    end

    before do
      allow(contacts_service).to receive(:new)
        .with(zip_code, 'demand')
        .and_return(service_instance)
    end

    it 'creates SelectRealtorContactService instance' do
      service_call

      expect(contacts_service).to have_received(:new).with(zip_code, 'demand')
    end

    it 'calls SelectRealtorContactService instance' do
      service_call

      expect(service_instance).to have_received(:call)
    end

    include_examples 'creates demand deal_assignment' do
      let(:realtor_contact) { demand_realtor_contact }
    end

    include_examples 'deactives supply deal assignments'

    it 'switches deal\'s realtor_contact' do
      expect { service_call }.to change { deal.reload.realtor_contact_id }
        .from(supply_realtor_contact.id)
        .to(demand_realtor_contact.id)
    end

    it 'switches deal\'s realtor' do
      expect { service_call }.to change { deal.reload.realtor_id }
        .from(supply_realtor.id)
        .to(demand_realtor.id)
    end

    it 'creates a SwitchedContact log entry' do
      expect { service_call }.to change { Log.where(action: 'SwitchedContact').count }.by(1)
    end

    it 'sends confirmation email to the newly assigned demand realtor' do
      service_call

      expect(MandrillMailWorker).to have_received(:perform_async)
        .with(
          mailer_class,
          mail_object_type,
          deal.id,
          realtor_contact_id: demand_realtor_contact.id,
          crm_user_id: area_manager.id,
          supply_realtor_contact_id: supply_realtor.id
        )
    end

    context 'when demand realtor contact equals supply realtor contact' do
      let(:demand_realtor_contact) { supply_realtor_contact }

      include_examples 'creates demand deal_assignment' do
        let(:realtor_contact) { demand_realtor_contact }
      end

      include_examples 'deactives supply deal assignments'
      include_examples 'doesn\'t send confirmation email'
      include_examples 'doesn\'t create SwitchContact log entry'

      it 'doesn\'t switch deal\'s realtor_contact' do
        expect { service_call }.not_to change { deal.reload.realtor_contact_id }
      end

      it 'doesn\'t switch deal\'s realtor' do
        expect { service_call }.not_to change { deal.reload.realtor_id }
      end
    end

    context 'when supply realtor contact has model supply_and_demand' do
      let(:supply_realtor_contact) do
        create(:realtor_contact, :with_crm_user, contactable: supply_realtor, realtor_model: 'supply_and_demand')
      end

      include_examples 'creates demand deal_assignment' do
        let(:realtor_contact) { supply_realtor_contact }
      end

      include_examples 'deactives supply deal assignments'
      include_examples 'doesn\'t send confirmation email'
      include_examples 'doesn\'t create SwitchContact log entry'

      it 'doesn\'t switch deal\'s realtor_contact' do
        expect { service_call }.not_to change { deal.reload.realtor_contact_id }
      end

      it 'doesn\'t switch deal\'s realtor' do
        expect { service_call }.not_to change { deal.reload.realtor_id }
      end
    end

    context 'when demand realtor for the given zip code doesn\'t exist' do
      subject(:raise_error_method) { described_class.new(deal).send(:raise_realtor_not_found_error) }

      let(:demand_realtor_contact) { nil }
      let(:error) { described_class::RealtorNotFoundError }
      let(:error_message) { 'No demand realtor found for the given zip code' }

      before { allow(ErrorTracker).to receive(:notify) }

      it { expect { raise_error_method }.to raise_error(error, error_message) }
      it { expect(service_call).to match(error_response) }

      include_examples 'doesn\'t send confirmation email'
      include_examples 'doesn\'t create SwitchContact log entry'
      include_examples 'calls ErrorTracker'
    end

    context 'when deal has crm appointments' do
      let(:appointment) do
        create(
          :crm_appointment,
          :upcoming,
          deleted_at: nil,
          associated: deal,
          crm_user_id: supply_realtor_contact.crm_user.id
        )
      end

      before do
        allow(Crm::AppointmentSyncWorker).to receive(:perform_async).with(appointment.id)
      end

      it 'switches crm appointments to demand realtor' do
        expect { service_call }.to change { appointment.reload.crm_user_id }
          .from(supply_realtor_contact.crm_user.id)
          .to(demand_realtor_contact.crm_user.id)
      end

      it 'calls Crm::AppointmentSyncWorker' do
        service_call

        expect(Crm::AppointmentSyncWorker).to have_received(:perform_async)
      end
    end

    context 'when deal has prompts' do
      let(:prompt) do
        create(
          :crm_prompt,
          completed: false,
          promptable: deal,
          crm_user_id: supply_realtor_contact.crm_user.id
        )
      end

      it 'switches crm prompts to demand realtor' do
        expect { service_call }.to change { prompt.reload.crm_user_id }
          .from(supply_realtor_contact.crm_user.id)
          .to(demand_realtor_contact.crm_user.id)
      end
    end

    context 'when deal has tasks' do
      let(:task) do
        create(
          :task,
          type: 'Task::CrmTask',
          object: deal,
          completed: false,
          deleted_at: nil,
          requested_for_id: supply_realtor_contact.crm_user.id,
          requested_for_type: 'Crm::User'
        )
      end

      it 'switches tasks to demand realtor' do
        expect { service_call }.to change { task.reload.requested_for_id }
          .from(supply_realtor_contact.crm_user.id)
          .to(demand_realtor_contact.crm_user.id)
      end
    end

    context 'when deal has documents' do
      let(:document) { create(:crm_energy_certificate_document, associated: deal) }
      let(:document_file) do
        create(
          :crm_document_file,
          crm_document: document,
          crm_user_id: supply_realtor_contact.crm_user.id
        )
      end

      it 'switches documents to demand realtor' do
        expect { service_call }.to change { document_file.reload.crm_user_id }
          .from(supply_realtor_contact.crm_user.id)
          .to(demand_realtor_contact.crm_user.id)
      end
    end
  end
end
