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


    end
  end
end
