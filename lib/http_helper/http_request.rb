module HttpHelper
  class HttpRequest

    include ::Util::ResultHelper

    DEFAULT_TIMEOUT = 10 #in seconds

    # Initialize
    #
    # * Author: Aniket
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @params [Integer] timeout(mandatory) - timeout in seconds
    # @params [String] base_url(mandatory) - base url
    #
    # Sets
    #
    # @return [HttpHelper::HttpRequest]
    #
    def initialize(params)
      @params = params
      @options = @params[:options] || {}

      @timeout = @options[:timeout] || DEFAULT_TIMEOUT

      @url = @params[:url]
      @request_parameters = @params[:request_parameters]
    end

    # make a post request
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def post
      uri = post_api_uri
      result = handle_with_exception(uri) do |http|
        http.post(uri.path, @request_parameters.to_query)
      end

      result
    end

    # make a get request
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def get
      uri = get_api_uri
      result = handle_with_exception(uri) do |http|
        http.get(uri)
      end

      result
    end

    private

    # Get API Url
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [URI]
    #
    def get_api_uri
      req_params = @request_parameters.present? ? "?#{@request_parameters.to_query}" : ""
      URI.parse(@url + req_params)
    end

    # Post API URI object
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [URI]
    #
    def post_api_uri
      URI(@url)
    end

    # Handle With Exception
    #
    # returns [Result::Base]
    #
    def handle_with_exception(uri)
      begin
        Timeout.timeout(@timeout) do
          http = setup_request(uri)
          result = yield(http)
          success_with_data({http_response:result})
        end
      rescue Timeout::Error => e
        return error_with_internal_code('h_hh_hwe_1',
                                        'Api error: Request time Out Error',
                                        GlobalConstant::ErrorCode.unprocessable_entity,
                                        {},[],'Time Out Error')

      rescue Exception => e
        exception_with_internal_code(e, 'h_hh_hwe_2',
                                     'Something Went Wrong',
                                     GlobalConstant::ErrorCode.unhandled_exception)
      end
    end

    # Create Request Data
    #
    # params:
    #   uri, URI object
    #
    # returns:
    #   http, Net::HTTP object
    #
    def setup_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http
    end

  end
end
