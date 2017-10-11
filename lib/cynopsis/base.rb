module Cynopsis

  class Base

    require 'http'

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Cynopsis::Base]
    #
    def initialize
    end

    private

    # GET request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def get_request(path, params = {})
      send_request_of_type('get', path, params)
    end

    # POST request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def post_request(path, params = {})
      send_request_of_type('post', path, params)
    end

    # PUT request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def put_request(path, params = {})
      send_request_of_type('put', path, params)
    end

    # Upload request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def upload_request(path, params = {})
      send_request_of_type('upload', path, params)
    end

    # Send required request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @param [String] request_type - request type
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def send_request_of_type(request_type, path, params)
      begin
        response = HTTP.headers('WEB2PY-USER-TOKEN' => GlobalConstant::Cynopsis.token)
        request_path = GlobalConstant::Cynopsis.base_url + path

        case request_type
          when 'get'
            response = response.get(request_path, :params => params)
          when 'post'
            response = response.post(request_path, :json => params)
          when 'put'
            response = response.put(request_path, :json => params)
          when 'upload'
            response = response.post(request_path, :form => params)
          else
            return error_with_data('cb_1',
                                              "Request type not implemented: #{request_type}",
                                              'Something Went Wrong.',
                                              GlobalConstant::ErrorAction.default,
                                              {})
        end

        case response.status
          when 200
            return success_with_data(response: Oj.load(response.body.to_s))
          else
            return error_with_data('cb_2',
                                              "Error in API call: #{response.status}",
                                              'Something Went Wrong.',
                                              GlobalConstant::ErrorAction.default,
                                              {})
        end
      rescue => e
        return error_with_data('cb_3',
                                          "Exception in API call: #{e.message}",
                                          'Something Went Wrong.',
                                          GlobalConstant::ErrorAction.default,
                                          {})
      end
    end

  end

end