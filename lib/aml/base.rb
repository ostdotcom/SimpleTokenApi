module Aml

  class Base

    require 'http'

    include Util::ResultHelperinclude Util::ResultHelper

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [Integer] client id (mandatory) - Client id
    # @return [Aml::Base]
    #
    def initialize(params)
      @client_id = params[:client_id]
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

    # Client aml detail obj
    #
    # * Author: Aman
    # * Date: 02/01/2018
    # * Reviewed By:
    #
    # @return [Ar] ClientAmlDetail object
    #
    def client_aml_detail
      @client_aml_detail ||= ClientAmlDetail.get_from_memcache(@client_id)
    end

    # Client aml detail decrypted token
    #
    # * Author: Aman
    # * Date: 02/01/2018
    # * Reviewed By:
    #
    # @return [String] ClientAmlDetail decrypted token
    #
    def get_client_aml_token_decrypted
      @client = Client.get_from_memcache(@client_id)

      r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
      return r unless r.success?

      api_salt_d = r.data[:plaintext]

      r = LocalCipher.new(api_salt_d).decrypt(client_aml_detail.token)
      return r unless r.success?

      api_secret_d = r.data[:plaintext]

      success_with_data({token_d: api_secret_d})
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
        r = get_client_aml_token_decrypted
        return r unless r.success?

        response = HTTP.headers('WEB2PY-USER-TOKEN' => r.data[:token_d])
        request_path = client_aml_detail.base_url + path

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
            response_hash = Oj.load(response.body.to_s)

            return error_with_data(
                'cb_2',
                "Error in API call: #{response.status}",
                'Something Went Wrong.',
                GlobalConstant::ErrorAction.default,
                response_hash['errors']
            ) if response_hash['errors'].present?

            return success_with_data(response: response_hash)
          else
            return error_with_data('cb_3',
                                   "Error in API call: #{response.status}",
                                   'Something Went Wrong.',
                                   GlobalConstant::ErrorAction.default,
                                   {})
        end
      rescue => e
        return error_with_data('cb_4',
                               "Exception in API call: #{e.message}",
                               'Something Went Wrong.',
                               GlobalConstant::ErrorAction.default,
                               {})
      end
    end

  end

end