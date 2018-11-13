module Request
  module OpsApi

    class Base < Request::Base


      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::Base]
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
      def send_request_of_type(ops_api_type, request_type, path, params)

        request_path = ((ops_api_type == GlobalConstant::PrivateOpsApi.private_ops_api_type) ?
                            GlobalConstant::PrivateOpsApi.base_url : GlobalConstant::PublicOpsApi.base_url) + path

        parameterized_token = {token: get_jwt_token(ops_api_type, params)}

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
      def get_jwt_token(ops_api_type, data)
        payload = {data: data}
        secret_key = (ops_api_type == GlobalConstant::PrivateOpsApi.private_ops_api_type) ?
                         GlobalConstant::PrivateOpsApi.secret_key :
                         GlobalConstant::PublicOpsApi.secret_key

        JWT.encode(payload, secret_key, 'HS256')
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

        Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")
        puts "http_response.class.name : #{http_response.class.name}"

        case http_response.code
          when 200
            if response_data['success']
              return success_with_data(HashWithIndifferentAccess.new(response_data['data']))
            else
              # web3_js_error = true is required because when API is down or any exception is raised or response is not 200
              # front end doesn't need to see invalid ethereum address
              return error_with_data(response_data['err']['code'],
                                     "Error in API call: #{http_response.status} - #{response_data['err']['msg']}",
                                     'Something Went Wrong.',
                                     GlobalConstant::ErrorAction.default,
                                     {web3_js_error: true})
            end
          else
            return error_with_data('r_b_pai_1',
                                   "Error in API call: #{http_response.status}",
                                   'Something Went Wrong.',
                                   GlobalConstant::ErrorAction.default,
                                   {})

        end

      end


    end
  end
end