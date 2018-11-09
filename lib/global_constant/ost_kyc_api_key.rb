# frozen_string_literal: true
module GlobalConstant

  class OstKycApiKey

    class << self

      def main_env_rsa_private_key
        GlobalConstant::Base.public_ops['main']['rsa_private_key']
      end

      def sandbox_env_rsa_public_key
        GlobalConstant::Base.public_ops['sandbox']['rsa_public_key']
      end

    end

  end

end

