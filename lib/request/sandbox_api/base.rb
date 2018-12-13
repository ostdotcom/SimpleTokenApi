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

        request_path = GlobalConstant::KycApiBaseDomain.get_base_domain_url_for_environment(environment) + path

        parameterized_token = {token: get_jwt_token(params)}

        r = send_request(request_type, request_path, parameterized_token)

        return r unless r.success?
        parse_api_response(r.data[:http_response])

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

      # Parse API response
      #
      # * Author: Aniket
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def parse_api_response(http_response)
        response_data = Oj.load(http_response.body.to_s, mode: :strict) rescue {}

        # Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")
        puts "http_response.class.name : #{http_response.class.name}"

        case http_response.code
          when 200
            return success_with_data(response_data['data'])
          when 400
            error_with_internal_code('r_sa_par_1',
                                     'ost kyc api error',
                                     GlobalConstant::ErrorCode.invalid_request_parameters,
                                     response_data['data'],
                                     response_data['err']['error_data'],
                                     response_data['err']['msg']
            )

          when 422
            error_with_internal_code('r_sa_par_2',
                                     'ost kyc api error',
                                     GlobalConstant::ErrorCode.unprocessable_entity,
                                     response_data['data'],
                                     response_data['err']['error_data'],
                                     response_data['err']['msg']
            )
          when 401
            error_with_internal_code('r_sa_par_3',
                                     'ost kyc api authentication failed',
                                     GlobalConstant::ErrorCode.unauthorized_access,
                                     {}, {},
                                     response_data['err']['msg']
            )

          when 500
            error_with_internal_code('r_sa_par_4',
                                     'ost kyc api bad gateway',
                                     GlobalConstant::ErrorCode.unhandled_exception,
                                     {}, {}, ''
            )
          when 403
            error_with_internal_code('r_sa_par_6',
                                     'ost kyc api forbidden',
                                     GlobalConstant::ErrorCode.forbidden,
                                     {}, {}, response_data['err']['msg']
            )
          else
            # HTTP error status code (500, 504...)
            exception_with_internal_code(Exception.new("Ost Kyc API STATUS CODE #{http_response.code.to_i}"),
                                         'ost_kyc_api_exception',
                                         'ost kyc api exception',
                                         GlobalConstant::ErrorCode.unhandled_exception,
                                         {},
                                         "Something went wrong")
        end

      end


    end
  end
end