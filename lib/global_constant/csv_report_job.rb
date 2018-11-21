# frozen_string_literal: true
module GlobalConstant

  class CsvReportJob

    class << self

      # statuses start
      # 
      def pending_status
        "pending"
      end

      def started_status
        "started"
      end

      def completed_status
        "completed"
      end

      def failed_status
        "failed"
      end
      
      # statuses end



      # report type start

      def kyc_report_type
        'kyc'
      end


      def user_report_type
        'user'
      end

      # report type end

    end

  end


end
