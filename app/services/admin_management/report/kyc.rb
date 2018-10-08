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
        super
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

      # filters allowed for the service
      #
      # * Author: Aman
      # * Date: 08/10/2018
      # * Reviewed By:
      #
      # @return [Hash] filters for the query
      #
      def model_filters
        GlobalConstant::UserKycDetail.filters
      end

      # sorting allowed for the service
      #
      # * Author: Aman
      # * Date: 08/10/2018
      # * Reviewed By:
      #
      # @return [Hash] sorting for the query
      #
      def model_sortings
        GlobalConstant::UserKycDetail.sorting
      end

    end

  end

end