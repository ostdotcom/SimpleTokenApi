module GlobalConstant

  class Event

    class << self

      ### result_type start ###

      def user_result_type
        'user'
      end

      def user_kyc_result_type
        'user_kyc'
      end

      ### result_type end ###

      ### source start ###

      def web_source
        'web'
      end

      def api_source
        'api'
      end

      def system_source
        'system'
      end

      ### source end ###


      ### name start ###

      def user_register_name
        'user_register'
      end

      def user_dopt_in_name
        'user_dopt_in'
      end

      def user_deleted_name
        'user_deleted'
      end

      def kyc_submit_name
        'kyc_submit'
      end

      def update_ethereum_address_name
        'update_ethereum_address'
      end

      def kyc_status_update_name
        'kyc_status_update'
      end

      ### name end ###


    end

  end
end
