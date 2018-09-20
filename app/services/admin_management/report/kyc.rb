module AdminManagement

  module Report

    class Kyc < Base

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
      # @return [AdminManagement::Report::Kyc]
      #
      def initialize(params)
        super
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
        super
      end

      private

      # Validate and sanitize
      #
      # * Author: Alpesh
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      def validate_and_sanitize
        r = super
        return r unless r.success?

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

      # type of report to be fetched
      #
      # * Author: Aman
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      # @return [String] report_type
      #
      def report_type
        GlobalConstant::CsvReportJob.kyc_report_type
      end

      # klass of job for this report to be processed
      #
      # * Author: Aman
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      # @return [Constant] klass Class name
      #
      def job_klass
        ReportJob::Kyc
      end

    end

  end

end