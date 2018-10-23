module HttpHelper
  class SignatureGenerator

    # Initialize
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @params [String] api_secret(mandatory) - api secret
    # @params [String] url(mandatory) - url
    # @params [Hash] request_parameters(mandatory) - hash
    #
    # @return [HttpHelper::SignatureGenerator]
    #
    def initialize(params)
      @params = params

      @url = @params[:url]
      @api_secret = @params[:api_secret]
      @request_parameters = @params[:request_parameters] || {}
    end

    # Get signature
    # :NOTE params inserted in url are not used to create signature
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def perform
      query_param = @request_parameters.to_query.gsub(/^&/, '')

      uri = URI(@url)
      final_url = "#{@url.split(uri.path).first}#{uri.path}"

      str = "#{final_url}?#{query_param}"
      generate_signature(str)
    end

    private

    # Get signature
    #
    # @params [String] string_to_sign(mandatory) - string to sign
    # @params [String] api_secret(mandatory) - api secret key
    #
    # * Author: Aniket
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def generate_signature(string_to_sign)
      digest = OpenSSL::Digest.new('sha256')
      Rails.logger.info("--------string_to_sign=>#{string_to_sign}-----")
      OpenSSL::HMAC.hexdigest(digest, @api_secret, string_to_sign)
    end

  end
end
