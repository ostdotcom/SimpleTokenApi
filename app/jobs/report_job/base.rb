module ReportJob

class Base < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  include ::Util::ResultHelper
  include ::Util::CsvHelper

  MYSQL_BATCH_SIZE = 100
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
      Rails.logger.info "ReportJob Worker got exception in job params- #{params} msg : #{se.message} trace : #{se.backtrace}"
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

    @has_data = nil
  end

  # fetch csv_report_job & admin obj
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  # Sets @csv_report_job, @admin, @client_id, @client, @filters, @sortings
  #
  def fetch_details
    @csv_report_job = CsvReportJob.where(id: @csv_report_job_id).first

    @filters = @csv_report_job.extra_data[:filters]
    @sortings = @csv_report_job.extra_data[:sortings]

    @admin = Admin.get_from_memcache(@csv_report_job.admin_id)

    @client_id = @csv_report_job.client_id
    @client = Client.get_from_memcache(@client_id)
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

    @has_data = get_data_from_db do |data|
      formatted_data = format_data(data)
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
      s3_url = CGI.escape(s3_url)
    end

    Email::HookCreator::SendTransactionalMail.new(
        client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
        email: @admin.email,
        template_name: GlobalConstant::PepoCampaigns.kyc_report_download_template,
        template_vars: {file_download_url: s3_url}
    ).perform
  end


  def get_data_from_db
    fail 'unimplemented method get_data_from_db'
  end

  def format_data(data)
    row = []
    csv_headers.each do |field_name|
      val = data[field_name.to_sym]
      row << (val.present? ? val.to_s.html_safe : nil)
    end
    row
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
        subject: "Exception in ProcessReportJob"
    ).deliver
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
    fail 'unimplemented method csv_headers'
  end

end

end