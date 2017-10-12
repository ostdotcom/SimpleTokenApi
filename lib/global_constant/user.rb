# frozen_string_literal: true
module GlobalConstant

  class User

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def deactived_status
        'deactived'
      end

      ### Status End ###

      ### Property start ###

      def token_sale_bt_done_property
        'token_sale_bt_done'
      end

      def token_sale_double_optin_done_property
        'token_sale_kyc_optin_done'
      end

      def token_sale_kyc_submitted_property
        'token_sale_kyc_submitted'
      end

      def token_sale_double_optin_mail_sent_property
        'token_sale_kyc_double_optin_mail_sent'
      end

      ### Property stop ###

    end

  end

end
