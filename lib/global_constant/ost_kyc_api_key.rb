# frozen_string_literal: true
module GlobalConstant

  class OstKycApiKey

    class << self

      def main_env_rsa_private_key
        @main_env_rsa_private_key ||= unescape_env_var(GlobalConstant::Base.ost_kyc_api['main']['rsa_private_key'])
      end

      def sandbox_env_rsa_public_key
        @sandbox_env_rsa_public_key ||= unescape_env_var(GlobalConstant::Base.ost_kyc_api['sandbox']['rsa_public_key'])
      end

      def unescape_env_var(val)
        eval %Q{"#{val}"}
      end

    end

  end

end

