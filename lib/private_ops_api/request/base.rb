module PrivateOpsApi
  module Request
    class Base

      include Util::ResultHelper

      require 'http'

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By:
      #
      # @return [PrivateOpsApi::Request::Base] returns an object of PrivateOpsApi::Request::Base class
      #
      def initialize
      end

      private

      # Send Api request
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def send_request_of_type(request_type, path, params)
        begin

          request_path = GlobalConstant::PrivateOpsApi.base_url + path

          case request_type
            when 'get'
              response = HTTP.get(request_path, params: params)
            when 'post'
              response = HTTP.post(request_path, json: params)
            else
              return error_with_data('poa_r_b_1',
                                     "Request type not implemented: #{request_type}",
                                     'Something Went Wrong.',
                                     GlobalConstant::ErrorAction.default,
                                     {})
          end

          case response.status
            when 200
              return success_with_data(response: Oj.load(response.body.to_s))
            else
              return error_with_data('poa_r_b_2',
                                     "Error in API call: #{response.status}",
                                     'Something Went Wrong.',
                                     GlobalConstant::ErrorAction.default,
                                     {})
          end
        rescue => e
          return error_with_data('poa_r_b_3',
                                 "Exception in API call: #{e.message}",
                                 'Something Went Wrong.',
                                 GlobalConstant::ErrorAction.default,
                                 {})
        end
      end

    end
  end
end