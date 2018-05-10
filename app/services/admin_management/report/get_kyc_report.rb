module AdminManagement

  module Report

    class GetKycReport < ServicesBase

      MAX_LIMIT_FOR_DOWNLOAD = 5
      TIMEFRAME_FOR_MAX_DOWNLOAD_IN_HOUR = 10

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

        success_with_data({success_message: "We are consolidating your CSV file. We will send an email on #{@admin.email}, with a link to download it. Please check your inbox in sometime."})

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
              'Previous request for download is already in process. Please try after some time',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

        last_min_download_time = Time.now - TIMEFRAME_FOR_MAX_DOWNLOAD_IN_HOUR.hours
        total_completed_jobs = CsvReportJob.where(client_id: @client_id, status: GlobalConstant::CsvReportJob.completed_status)
                                   .where('created_at > ?', last_min_download_time).count

        if total_completed_jobs >= MAX_LIMIT_FOR_DOWNLOAD
          db_resp = CsvReportJob.where(client_id: @client_id, status: GlobalConstant::CsvReportJob.completed_status)
                        .where('created_at > ?', last_min_download_time).select('min(created_at) as last_download_time').first

          time_str = time_diff_string(db_resp.last_download_time)

          return error_with_data(
              'am_r_gkr_vircbt_2',
              "Maximum of #{total_completed_jobs} csv downloads for today is done.",
              "You can only download the CSV #{MAX_LIMIT_FOR_DOWNLOAD} times in #{TIMEFRAME_FOR_MAX_DOWNLOAD_IN_HOUR} hours. Please try again after #{time_str}.",
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end
        success
      end

      # give display string for time left to download another csv
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # @return [String] return human readable string for time difference rounded off to 15 minutes
      #
      def time_diff_string(last_download_time)
        timestamp_diff = last_download_time.to_i - Time.now.to_i + TIMEFRAME_FOR_MAX_DOWNLOAD_IN_HOUR.hours.to_i
        time_in_hour = timestamp_diff / (60 * 60)

        timestamp_diff_in_min = timestamp_diff % (60 * 60)
        time_in_min = (timestamp_diff_in_min / (15.0 * 60)).ceil

        if time_in_min == 4
          time_in_min = 0
          time_in_hour += 1
        end

        time_str = ""
        time_str = "#{time_in_hour} hour" if time_in_hour > 0
        time_str += " #{time_in_min * 15} minutes" if time_in_min > 0

        time_str
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