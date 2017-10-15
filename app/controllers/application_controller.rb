class ApplicationController < ActionController::API

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception

  [
    ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  # Sanitize URL params
  include Sanitizer

  before_action :sanitize_params

  after_action :set_response_headers

  # Action not found handling. Also block "/"
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def not_found
    r = Result::Base.error({
                             error: 'ac_1',
                             error_message: 'Resource not found',
                             http_code: GlobalConstant::ErrorCode.not_found
                           })
    render_api_response(r)
  end

  private

  # Method for sanitizing params
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def sanitize_params
    sanitize_params_recursively(params)
  end

  # Get user agent
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def http_user_agent
    # User agent is required for cookie validation
    request.env['HTTP_USER_AGENT'].to_s
  end

  # Get Ip Address
  #
  # * Author: Aman
  # * Date: 15/10/2017
  # * Reviewed By:
  #
  def ip_address
    request.remote_ip.to_s
  end

  # Render API Response
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [Result::Base] service_response is an object of Result::Base class
  #
  def render_api_response(service_response)
    # calling to_json of Result::Base
    response_hash = service_response.to_json
    http_status_code = service_response.http_code

    # filter out not allowed http codes
    http_status_code = GlobalConstant::ErrorCode.ok unless GlobalConstant::ErrorCode.allowed_http_codes.include?(http_status_code)

    # sanitizing out error and data. only display_text and display_heading are allowed to be sent to FE.
    if !service_response.success? && !Rails.env.development?
      err = response_hash.delete(:err) || {}
      response_hash[:err] = {
        display_text: (err[:display_text].to_s),
        display_heading: (err[:display_heading].to_s),
        error_data: (err[:error_data] || {})
      }

      response_hash[:data] = {}
    end

    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)
  end

  # After action for setting the response headers
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def set_response_headers
    response.headers["X-Robots-Tag"] = 'noindex, nofollow'
    response.headers["Content-Type"] = 'application/json; charset=utf-8'
  end

  # Cookies to be cleared after user logout
  #
  # * Author:: Aman
  # * Date:: 13/07/2017
  # * Reviewed By: Sunil
  #
  def clear_all_cookie
    cookies_not_to_be_deleted = []
    cookies.each do |key, _|
      next if cookies_not_to_be_deleted.include?(key)
      cookies.delete(key.to_sym, domain: :all)
    end
  end

end
