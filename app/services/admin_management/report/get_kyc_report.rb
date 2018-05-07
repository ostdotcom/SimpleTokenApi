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
      # @params [Hash] filters (optional)
      # @params [Hash] sortings (optional)
      #
      # @return [AdminManagement::Report::GetKycReport]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @filters = @params[:filters]
        @sortings = @params[:sortings]

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

        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        r = validate_if_request_can_be_taken
        return r unless r.success?

        create_csv_report_job

        success_with_data({success_message: "Success! We are consolidating your CSV file. We will send an email on #{@admin.email}, with a link to download it. Please check your inbox in sometime."})

      end

      private

      # Validate and sanitize
      #
      # * Author: Alpesh
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
        @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))

        if @filters.present?

          error_data = {}

          @filters.each do |key, val|

            if GlobalConstant::UserKycDetail.filters[key.to_s].blank?
              return error_with_data(
                  'am_r_gkr_vas_1',
                  'Invalid Parameters.',
                  'Invalid Filter type passed',
                  GlobalConstant::ErrorAction.default,
                  {},
                  {}
              )
            end

            filter_data = GlobalConstant::UserKycDetail.filters[key][val]
            error_data[key] = 'invalid value for filter' if filter_data.nil?
          end

          return error_with_data(
              'am_r_gkr_vas_2',
              'Invalid Filter Parameter value',
              '',
              GlobalConstant::ErrorAction.default,
              {},
              error_data
          ) if error_data.present?

        end


        if @sortings.present?
          error_data = {}

          @sortings.each do |key, val|

            if GlobalConstant::UserKycDetail.sorting[key.to_s].blank?
              return error_with_data(
                  'am_r_gkr_vas_3',
                  'Invalid Parameters.',
                  'Invalid Sort type passed',
                  GlobalConstant::ErrorAction.default,
                  {},
                  {}
              )
            end

            sort_data = GlobalConstant::UserKycDetail.sorting[key][val]
            error_data[key] = 'invalid value for sorting' if sort_data.nil?
          end

          return error_with_data(
              'am_r_gkr_vas_4',
              'Invalid Sort Parameter value',
              '',
              GlobalConstant::ErrorAction.default,
              {},
              error_data
          ) if error_data.present?
        end

        success
      end

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
              'Previous request for download is already in process',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

        total_completed_jobs = CsvReportJob.where(client_id: @client_id, status: GlobalConstant::CsvReportJob.completed_status)
                                   .where('created_at > ?', Time.now - 1.day).count

        if total_completed_jobs >= MAX_LIMIT_FOR_1_DAY
          db_resp = CsvReportJob.where(client_id: @client_id, status: GlobalConstant::CsvReportJob.completed_status)
                                     .where('created_at > ?', Time.now - 1.day).select('min(created_at) as next_download_time').first

          time_str = db_resp.next_download_time.strftime("%H:%M %p %z")
          # "tomorrow" string to be relative to next time str

          return error_with_data(
              'am_r_gkr_vircbt_2',
              "Maximum of #{total_completed_jobs} csv downloads for today is done.",
              "You can only download the CSV #{MAX_LIMIT_FOR_1_DAY} times in 24 hours. Please try again after #{time_str}.",
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

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
                                              status: GlobalConstant::CsvReportJob.pending_status, extra_data: {filters: @filters, sortings: @sortings})

        BgJob.enqueue(
            ProcessKycReportJob,
            {csv_report_job_id: csv_report_job.id}
        )

        Rails.logger.info('---- enqueue_job process_csv_report_job done')

      end


    end

  end

end