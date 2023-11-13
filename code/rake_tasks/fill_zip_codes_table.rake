# frozen_string_literal: true

require 'csv'

# This task is needed to parse a .csv file with zip_codes and fill zip_codes table.
# If 'skip_uniqueness_errors' argument is passed, ActiveRecord::RecordNotUnique
# error messages will not be displayed.
# Execute task with an argument:
#   bash: rake fill_table_with_data:zip_codes[skip_uniqueness_errors]
#   zsh: rake fill_table_with_data:zip_codes\[skip_uniqueness_errors\]
namespace :fill_table_with_data do
  desc 'Fills zip_codes table'

  task :zip_codes, %i[skip_uniqueness_errors] => :environment do |_, args|
    include ZipCodesHelper

    table = parse_csv_file

    puts "Process started. #{table.size} zip_codes to create\n\n"

    @created_records = 0
    @creation_failed_records = 0

    table.each_with_index { |row, index| create_zip_code(row, index, args) }

    puts "Process finished. Created records: #{@created_records}, creation failed records: #{@creation_failed_records}"
  rescue Aws::S3::Errors::ServiceError => e
    puts "#{e.class}: #{e.exception}"
  end
end

module ZipCodesHelper
  AWS_REGION = 'eu-central-1'
  AWS_BUCKET_NAME = 'csv-files'
  AWS_FILE_KEY = 'zip_codes.csv'

  def parse_csv_file
    CSV.parse(file_body, headers: true, converters: [empty_space_converter, integer_converter])
  end

  def file_body
    s3_client.get_object(
      bucket: AWS_BUCKET_NAME,
      key: AWS_FILE_KEY
    ).body
  end

  def s3_client
    Aws::S3::Client.new(
      region: AWS_REGION,
      credentials: Aws::Credentials.new(
        Rails.application.secrets.aws_access_key_id,
        Rails.application.secrets.aws_secret_access_key
      )
    )
  end

  def empty_space_converter
    ->(field) { field&.strip }
  end

  def integer_converter
    columns_to_convert = %w[crm_user_id manager_id]

    lambda { |field, field_info|
      columns_to_convert.include?(field_info.header) ? field&.to_i : field
    }
  end

  def create_zip_code(row, index, args)
    ZipCode.create!(
      zip_code: row['zip_code'],
      face_model: row['face_model'],
      crm_user_id: validate_crm_user(row['crm_user_id']),
      manager_id: validate_crm_user(row['manager_id'])
    )

    @created_records += 1
  rescue StandardError => e
    @creation_failed_records += 1

    unless skip_error_message_output?(e, args)
      puts "Failed to create_zip_code: row: #{index + 2}, zip_code: #{row['zip_code']}"
      puts "Error message: #{e.message}\n\n"
    end
  end

  def validate_crm_user(user_id)
    return nil unless user_id
    return user_id if Crm::User.find(user_id)
  end

  def skip_error_message_output?(error, args)
    error.is_a?(ActiveRecord::RecordNotUnique) && args[:skip_uniqueness_errors].present?
  end
end
