module BonusApproval

  class Base < ApplicationJob

    queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

    require 'csv'

    BATCH_SIZE = 100

    # Perform
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def perform(params)

      init_params(params)

      start_export_process

    end

    private

    # initialize
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    # Sets @file_name, @local_file_path, @new_rows, @updated_rows, @error_skipped_rows, @kyc_updated_count
    #
    def init_params(params)
      @file_name = params[:bonus_file_name]
      @local_file_path = "#{Rails.root}/tmp/#{@file_name}"

      @new_rows, @updated_rows, @error_skipped_rows, @kyc_updated_count = 0, 0, 0, 0
    end

    # Download file
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def download_file
      url = Aws::S3Manager.new('kyc', 'admin')
      s_url = url.get_signed_url_for(GlobalConstant::Aws::Common.external_data_bucket, "#{Rails.env}/bonus-approval/#{@file_name}")
      download_status = system("wget -O #{@local_file_path} '#{s_url}'")
      fail "couldn't download file from #{url}" unless download_status
    end

    # Send report to admin
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def send_report_mail
      send_to = Rails.env.production? ? GlobalConstant::Email.default_pm_to : GlobalConstant::Email.default_to
      ApplicationMailer.notify(
          to: send_to,
          body: {},
          data: {
              error_skipped_rows: @error_skipped_rows,
              new_rows: @new_rows,
              updated_rows: @updated_rows,
              kyc_updated_count: @kyc_updated_count
          },
          subject: report_mail_subject
      ).deliver
    end

    # Start Export process to be implemented in parent class
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def start_export_process
      fail 'start export process undefined'
    end

    # Report email subject to be implemented in parent class
    #
    # * Author: Aman
    # * Date: 06/11/2017
    # * Reviewed By: Sunil
    #
    def report_mail_subject
      fail 'report_mail_subject undefined'
    end

  end
end
