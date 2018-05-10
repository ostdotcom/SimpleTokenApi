# frozen_string_literal: true
module GlobalConstant

  class EditKycRequest

    class << self


      ### Edit KYC request status start ####

      def unprocessed_status
        'unprocessed'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

      def in_process_status
        'in_process'
      end

      def unwhitelist_in_process_status
        'unwhitelist_in_process'
      end

      ### Edit KYC request status end ####


      ### Edit KYC request update action items start ####

      def open_case_update_action
        'open_case'
      end

      def update_ethereum_action
        'update_ethereum'
      end

      ### Edit KYC request update action items end ####


    end

  end

end
