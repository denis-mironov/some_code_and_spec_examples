# frozen_string_literal: true

shared_examples 'creates zip_code' do |zip_code, face_model|
  it 'creates zip_code' do
    expect { execute_task }.to change(
      ZipCode.where(
        zip_code: zip_code,
        face_model: face_model,
        crm_user_id: crm_user_id,
        regional_manager_id: regional_manager_id
      ), :count
    ).by(1)
  end
end

shared_examples 'outputs start and finish messages' do
  it { expect { execute_task }.to output(start_message).to_stdout }
  it { expect { execute_task }.to output(finish_message).to_stdout }
end

shared_examples 'outputs start message, finish message and error messages' do
  it { expect { execute_task }.to output(start_message).to_stdout }
  it { expect { execute_task }.to output(finish_message).to_stdout }
  it { expect { execute_task }.to output(error_message).to_stdout }

  it 'outputs validation error' do
    I18n.with_locale(:en) do
      expect { execute_task }.to output(validation_error_message).to_stdout
    end
  end
end

describe 'rake fill_table_with_data:zip_codes', type: :task do
  Rails.application.load_tasks

  subject(:execute_task) { Rake::Task['fill_table_with_data:zip_codes'].execute }

  let(:file_path) { 'spec/fixtures/test_files/zip_codes.csv' }
  let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join(file_path), 'file/csv') }
  let(:aws_client) { Aws::S3::Client.new(stub_responses: { get_object: { body: csv_file.read } }) }
  let(:start_message) { /Process started. 2 zip_codes to create/ }
  let(:finish_message) { /Created records: #{created_records}, creation failed records: #{failed_records}/ }
  let(:created_records) { 2 }
  let(:failed_records) { 0 }

  let(:crm_user_id) { create(:crm_user).id }
  let(:regional_manager_id) { create(:crm_user).id }
  let(:one_face_model) { 'one_face' }
  let(:two_face_model) { 'two_face' }
  let(:zip_code_1) { '21423' }
  let(:zip_code_2) { '21682' }
  let(:rows) do
    [
      %w[zip_code face_model crm_user_id regional_manager_id],
      [zip_code_1, one_face_model, crm_user_id, regional_manager_id],
      [zip_code_2, two_face_model, crm_user_id, regional_manager_id]
    ]
  end

  before do
    CSV.open(file_path, 'w') do |csv|
      rows.each { |row| csv << row }
    end

    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
    csv_file.close
  end

  after { FileUtils.rm_f(file_path) }

  context 'when all fields in .csv file are correct' do
    include_examples 'creates zip_code', '21423', 'one_face'
    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start and finish messages'
  end

  context 'when some fields in .csv file have empty spaces' do
    let(:one_face_model) { 'one_face ' }
    let(:zip_code_2) { ' 21682' }

    include_examples 'creates zip_code', '21423', 'one_face'
    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start and finish messages'
  end

  context 'when zip_code field in .csv file is incorrect' do
    let(:zip_code_1) { '214231' }
    let(:created_records) { 1 }
    let(:failed_records) { 1 }
    let(:error_message) { /Failed to create zip_code: row: 2, zip_code: #{zip_code_1}/ }
    let(:validation_error_message) { /Not a valid Zip Code/ }

    it { expect { execute_task }.not_to change(ZipCode.where(zip_code: zip_code_1), :count) }

    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start message, finish message and error messages'
  end

  context 'when zip_code field in .csv file is nil' do
    let(:zip_code_1) { nil }
    let(:created_records) { 1 }
    let(:failed_records) { 1 }
    let(:error_message) { /Failed to create zip_code: row: 2, zip_code: / }
    let(:validation_error_message) { /The Zip Code is empty/ }

    it { expect { execute_task }.not_to change(ZipCode.one_face, :count) }

    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start message, finish message and error messages'
  end

  context 'when face_model field in .csv file is incorrect' do
    let(:one_face_model) { 'incorrect_face_model' }
    let(:created_records) { 1 }
    let(:failed_records) { 1 }
    let(:error_message) { /Failed to create zip_code: row: 2, zip_code: #{zip_code_1}/ }
    let(:validation_error_message) { /not a valid face_model/ }

    it { expect { execute_task }.not_to change(ZipCode.where(zip_code: zip_code_1), :count) }

    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start message, finish message and error messages'
  end

  context 'when face_model field in .csv file is nil' do
    let(:one_face_model) { nil }
    let(:created_records) { 1 }
    let(:failed_records) { 1 }
    let(:error_message) { /Failed to create zip_code: row: 2, zip_code: #{zip_code_1}/ }
    let(:validation_error_message) { /The face model is empty/ }

    it { expect { execute_task }.not_to change(ZipCode.where(zip_code: zip_code_1), :count) }

    include_examples 'creates zip_code', '21682', 'two_face'
    include_examples 'outputs start message, finish message and error messages'
  end

  context 'when user\'s data is incorrect' do
    let(:created_records) { 0 }
    let(:failed_records) { 2 }
    let(:error_message) { /Failed to create zip_code/ }
    let(:validation_error_message) { /Couldn't find Crm::User with 'id'=123/ }

    context 'when crm_user_id field in .csv file is incorrect' do
      let(:crm_user_id) { '123' }

      it { expect { execute_task }.not_to change(ZipCode, :count) }

      include_examples 'outputs start message, finish message and error messages'
    end

    context 'when regional_manager_id field in .csv file is incorrect' do
      let(:regional_manager_id) { '12345' }

      it { expect { execute_task }.not_to change(ZipCode, :count) }

      include_examples 'outputs start message, finish message and error messages'
    end
  end

  context 'when crm_user_id or regional_manager_id field in .csv file is nil' do
    context 'when crm_user_id is nil' do
      let(:crm_user_id) { nil }

      include_examples 'creates zip_code', '21423', 'one_face'
      include_examples 'creates zip_code', '21682', 'two_face'
      include_examples 'outputs start and finish messages'
    end

    context 'when regional_manager_id is nil' do
      let(:regional_manager_id) { nil }

      include_examples 'creates zip_code', '21423', 'one_face'
      include_examples 'creates zip_code', '21682', 'two_face'
      include_examples 'outputs start and finish messages'
    end

    context 'when both of them are nil' do
      let(:crm_user_id) { nil }
      let(:regional_manager_id) { nil }

      include_examples 'creates zip_code', '21423', 'one_face'
      include_examples 'creates zip_code', '21682', 'two_face'
      include_examples 'outputs start and finish messages'
    end
  end

  context 'when zip_code with given zip_code is already exists' do
    let(:created_records) { 1 }
    let(:failed_records) { 1 }
    let(:error_message) { /Failed to create zip_code: row: 2, zip_code: #{zip_code_1}/ }
    let(:validation_error_message) { /Duplicate entry '#{zip_code_1}'/ }

    before { create(:zip_code, zip_code: zip_code_1) }

    context 'when flag to skip uniqueness errors is passed' do
      subject(:execute_task_with_args) do
        Rake::Task['fill_table_with_data:zip_codes']
          .execute(skip_uniqueness_errors: 'skip_uniqueness_errors')
      end

      it 'creates zip_code' do
        expect { execute_task_with_args }.to change(
          ZipCode.where(
            zip_code: '21682',
            face_model: 'two_face',
            crm_user_id: crm_user_id,
            regional_manager_id: regional_manager_id
          ), :count
        ).by(1)
      end

      it { expect { execute_task_with_args }.not_to change(ZipCode.where(zip_code: zip_code_1), :count) }
      it { expect { execute_task_with_args }.to output(start_message).to_stdout }
      it { expect { execute_task_with_args }.to output(finish_message).to_stdout }
      it { expect { execute_task_with_args }.not_to output(error_message).to_stdout }
      it { expect { execute_task_with_args }.not_to output(validation_error_message).to_stdout }
    end

    context 'when flag to skip uniqueness errors is not passed' do
      it { expect { execute_task }.not_to change(ZipCode.where(zip_code: zip_code_1), :count) }

      include_examples 'creates zip_code', '21682', 'two_face'
      include_examples 'outputs start message, finish message and error messages'
    end
  end
end
