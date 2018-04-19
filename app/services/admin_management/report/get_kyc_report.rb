module AdminManagement

  module Report

    class GetKycReport < ServicesBase

      MAX_LIMIT_FOR_1_DAY = 5

      # Initialize
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - this is the client id
      # @params [String] admin_id (mandatory) - this is the email entered
      #
      # @params [String] filters (optional) - this is a hash of filters to be applied for csv data
      #
      # @return [AdminManagement::Report::GetKycReport]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @filters = @params[:filters]

        @client = nil
        @admin = nil
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = validate_if_request_can_be_taken
        return r unless r.success?

        create_csv_report_job

        success

      end

      private

      # validate if no pending requests for this client is pending and limit not reached
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_if_request_can_be_taken

        if CsvReportJob.where(client_id: @client_id, status: [GlobalConstant::CsvReportJob.pending_status, GlobalConstant::CsvReportJob.started_status])
               .where('created_at > ?', Time.now - 2.hour).exists?

          return error_with_data(
              'am_r_gkr_vircbt_1',
              'previous request for download is already in process',
              'previous request for download is already in process',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

        total_completed_jobs = CsvReportJob.where(client_id: @client_id, status: GlobalConstant::CsvReportJob.completed_status)
                                       .where('created_at > ?', Time.now - 1.day).count

        return error_with_data(
            'am_r_gkr_vircbt_2',
            "Maximum of #{total_completed_jobs} csv downloads for today is done.",
            "Maximum of #{total_completed_jobs} csv downloads for today is done.",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if total_completed_jobs >= MAX_LIMIT_FOR_1_DAY

        success
      end

      # create a record in csv report job and enqueue job
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def create_csv_report_job
        csv_report_job = CsvReportJob.create!(client_id: @client_id, admin_id: @admin_id,
                                              status: GlobalConstant::CsvReportJob.pending_status, extra_data: {})

        BgJob.enqueue(
            ProcessKycReportJob,
            {csv_report_job_id: csv_report_job.id}
        )

        Rails.logger.info('---- enqueue_job process_csv_report_job done')

      end


    end

  end

end