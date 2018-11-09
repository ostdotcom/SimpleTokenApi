module Request
  module SandboxApi

    class Base < Request::Base


      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::SandboxApi::Base]
      #
      def initialize
        super
      end

      private

      # Send Api request
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def send_request_of_type(environment, request_type, path, params)

        request_path =   GlobalConstant::KycApiBaseDomain.get_base_domain_url_for_environment(environment)  + path

        parameterized_token = {token: get_jwt_token(params)}

        send_request(request_type, request_path, parameterized_token)

      end

      # Create encrypted Token for whitelisting parameter
      #
      # * Author: Abhay
      # * Date: 31/10/2017
      # * Reviewed By: Kedar
      #
      # @params [String] private ops/ public ops
      # @params [Hash] data
      #
      # @return [String] Encoded token
      #
      def get_jwt_token(data)
        # the token will be valid for upto 2 mins only
        exp = Time.now.to_i + 2.minutes.to_i
        payload = {data: data, exp: exp}
        rsa_pvt_key = OpenSSL::PKey::RSA.new(GlobalConstant::OstKycApiKey.main_env_rsa_private_key)
        JWT.encode(payload, rsa_pvt_key, 'RS256')
      end

    end
  end
end