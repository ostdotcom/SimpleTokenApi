class ProcessKycReportJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  include ::Util::ResultHelper
  include ::Util::CsvHelper

  MYSQL_BATCH_SIZE = 100
  IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL = 7.days.to_i
  ZIP_FILE_EXPIRY_TIMESTAMP_INTERVAL = 12.hours.to_i

  # Perform
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def perform(params)
    init_params(params)
    begin
      fetch_details
      r = validate
      return r unless r.success?
      update_job_status(GlobalConstant::CsvReportJob.started_status)
      process_and_upload_csv
      email_file_url
      update_job_status(GlobalConstant::CsvReportJob.completed_status)
    rescue StandardError => se
      Rails.logger.info "ProcessKycReportJob Worker got exception in job params- #{params} msg : #{se.message} trace : #{se.backtrace}"
      send_error_mail({exception: {message: se.message, backtrace: se.backtrace}})
      update_job_status(GlobalConstant::CsvReportJob.failed_status)
    end
  end

  private

  # Init params
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    @params = params
    @csv_report_job_id = params[:csv_report_job_id]

    @csv_report_job = nil
    @admin = nil
    @client_id = nil
    @client = nil
    @client_kyc_config = nil
    @has_data = nil
  end

  # fetch csv_report_job & admin obj
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # Sets @csv_report_job, @admin, @client_id, @client_kyc_config, @client
  #
  def fetch_details
    @csv_report_job = CsvReportJob.where(id: @csv_report_job_id).first
    @admin = Admin.get_from_memcache(@csv_report_job.admin_id)

    @client_id = @csv_report_job.client_id
    @client = Client.get_from_memcache(@client_id)
    @client_kyc_config = ClientKycConfigDetail.get_from_memcache(@client_id)
  end

  # validate
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate

    if @csv_report_job.status != GlobalConstant::CsvReportJob.pending_status
      send_error_mail("csv report job status should be pending. status-#{@csv_report_job.status}")
      return error_with_data(
          'pkrj_1',
          'Job is not in pending state',
          'Job is not in pending state',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    if @admin.blank? || (@admin.default_client_id != @csv_report_job.client_id) || @admin.role != GlobalConstant::Admin.super_admin_role
      send_error_mail("Admin does not have permission to download csv")
      update_job_status(GlobalConstant::CsvReportJob.failed_status)
      return error_with_data(
          'pkrj_2',
          'Admin does not have permission to download csv',
          'Admin does not have permission to download csv',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    success
  end

  # start creating csv for kyc data and upload to s3
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # Sets @has_data
  #
  def process_and_upload_csv

    @has_data = get_kyc_data_from_db do |user_data|
      formatted_data = format_user_data(user_data)
      c_add formatted_data
    end

    if @has_data
      zip_folder
      upload_to_s3
      delete_local_files
    end

  end

  def upload_to_s3
    s3_manager_obj.store(
        upload_s3_path,
        File.open("#{csv_file_folder_full_path}.zip"),
        GlobalConstant::Aws::Common.report_bucket,
        {
            content_type: 'application/zip',
            expires: Time.now + 7.day,
        }
    )
  end

  def email_file_url
    s3_url = ''

    if @has_data
      s3_url = s3_manager_obj.get_signed_url_for(
          GlobalConstant::Aws::Common.report_bucket,
          upload_s3_path,
          {
              expires_in: ZIP_FILE_EXPIRY_TIMESTAMP_INTERVAL
          }
      )
    end

    ApplicationMailer.notify(
        body: {has_data: @has_data, file_url: s3_url},
        subject: "DOWNLOAD CSV RESPONSE"
    ).deliver

    #todo send email
    #
    # Email::HookCreator::SendTransactionalMail.new(
    #     client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
    #     email: @admin.email,
    #     template_name: GlobalConstant::PepoCampaigns.low_whitelister_balance_template,
    #     template_vars: {has_data: @has_data}
    # ).perform
  end


  def get_kyc_data_from_db
    offset = 0

    while (true)
      user_extended_detail_ids = []
      user_ids = []

      user_kyc_details = UserKycDetail.where(client_id: @client_id).order('id').limit(MYSQL_BATCH_SIZE).offset(offset).all
      break if user_kyc_details.blank?

      user_kyc_details.each do |user_kyc_detail|
        user_extended_detail_ids << user_kyc_detail.user_extended_detail_id
        user_ids << user_kyc_detail.user_id
      end

      users = User.where(client_id: @client_id, id: user_ids).all.index_by(&:id)
      user_extended_details = UserExtendedDetail.where(id: user_extended_detail_ids).all.index_by(&:id)

      user_kyc_details.each do |user_kyc_detail|
        user = users[user_kyc_detail.user_id]
        user_extended_detail = user_extended_details[user_kyc_detail.user_extended_detail_id]
        user_data = get_user_data(user, user_kyc_detail, user_extended_detail)
        yield(user_data)
      end

      offset += MYSQL_BATCH_SIZE
    end

    return offset > 0
  end

  def format_user_data(user_data)
    row = []
    csv_headers.each do |field_name|
      row << user_data[field_name.to_sym]
    end
    row
  end

  def get_user_data(user, user_kyc_detail, user_extended_detail)
    kyc_salt_e = user_extended_detail.kyc_salt
    r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
    throw 'unable to decrypt salt from kms' unless r.success?
    kyc_salt_d = r.data[:plaintext]
    local_cipher_obj = LocalCipher.new(kyc_salt_d)

    user_data = {
        email: user.email,
        submitted_at: Time.at(user_extended_detail.created_at).strftime("%d/%m/%Y %H:%M %z"), # test time with zone
        admin_status: user_kyc_detail.admin_status,
        cynopsis_status: user_kyc_detail.cynopsis_status
    }
    user_data[:whitelist_status] = user_kyc_detail.whitelist_status if other_kyc_fields.include?('whitelist_status')

    kyc_form_fields.each do |field_name|
      if GlobalConstant::ClientKycConfigDetail.unencrypted_fields.include?(field_name)
        user_data[field_name.to_sym] = user_extended_detail[field_name]
      elsif GlobalConstant::ClientKycConfigDetail.encrypted_fields.include?(field_name)
        if field_name == GlobalConstant::ClientKycConfigDetail.residence_proof_file_path_kyc_field && user_extended_detail.residence_proof_file_path.blank?
          user_data[field_name.to_sym] = nil
          next
        end
        decrypted_data = local_cipher_obj.decrypt(user_extended_detail[field_name]).data[:plaintext]
        decrypted_data = get_url(decrypted_data) if GlobalConstant::ClientKycConfigDetail.image_url_fields.include?(field_name)
        user_data[field_name.to_sym] = decrypted_data
      else
        throw "invalid kyc field-#{field_name}"
      end
    end

    return user_data
  end

  # update status of job
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # @param [String] status - status of row to be updated
  #
  def update_job_status(status)
    @csv_report_job.status = status
    @csv_report_job.save!
  end

  # Send Error mail to dev
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  def send_error_mail(body)
    ApplicationMailer.notify(
        body: body,
        data: @params,
        subject: "Exception in ProcessKycReportJob"
    ).deliver
  end

  def kyc_form_fields
    @kyc_fields ||= @client_kyc_config.kyc_fields_array - [GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field]
  end

  def other_kyc_fields
    @kyc_status_fields ||=
        begin
          fields = ['admin_status', 'cynopsis_status', 'submitted_at']
          fields << 'whitelist_status' if @client.is_whitelist_setup_done?
          fields
        end
  end

  def get_url(s3_path)
    return '' unless s3_path.present?
    s3_manager_obj.get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path, {expires_in: IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL})
  end

  def s3_manager_obj
    @s3_manager_obj ||= Aws::S3Manager.new('kyc', 'admin')
  end

  def csv_file_folder_full_path
    @csv_file_folder_full_path ||= Rails.root.to_s + "/../shared/csv_downloads/" + folder_name
  end

  def folder_name
    @folder_name ||= Digest::MD5.hexdigest("#{@csv_report_job_id}-#{Time.now.to_f}-#{rand}")
  end

  def upload_s3_path
    @upload_s3_path ||= "csv_download/#{@client_id}/#{Time.now.strftime('%y-%m-%d')}/#{folder_name}"
  end

  def csv_headers
    ['email'] + other_kyc_fields + kyc_form_fields
  end

end

