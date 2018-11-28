module GlobalConstant
  class AdminActivityChangeLogger
    class << self
      ######################## Source ########################
      def script_source
        'script'
      end

      def web_source
        'web'
      end

      ####################### Table Names ####################

      def client_token_sale_details_table
        'client_token_sale_details'
      end

      def client_webhook_settings_table
        'client_webhook_settings'
      end

      def client_kyc_detail_api_activations_table
        'client_kyc_detail_api_activations'
      end

      def client_kyc_config_details_table
        'client_kyc_config_details'
      end

      def client_whitelist_details_table
        'client_whitelist_details'
      end

    end
  end
end
