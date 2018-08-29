module GlobalConstant

  class KycApiBaseDomain

    class << self

      def get_base_domain_url_for_environment(env)
        GlobalConstant::Base.kyc_api_base_domain[env]
      end

    end

  end

end

