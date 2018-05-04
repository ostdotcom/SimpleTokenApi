class ApplicationController < ActionController::API

  # Sanitize URL params
  include Sanitizer

  before_action :sanitize_params

  after_action :set_response_headers

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

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
      ApplicationMailer.notify(
        body: {},
        data: {
          response_hash: response_hash
        },
        subject: 'Error in KYC submit API'
      ).deliver if params[:action] == 'kyc_submit' && params[:controller] == 'web/saas_user/token_sale'

      err = response_hash.delete(:err) || {}
      response_hash[:err] = {
          display_text: (err[:display_text].to_s),
          display_heading: (err[:display_heading].to_s),
          error_data: (err[:error_data] || {}),
          code: (err[:code] || {})
      }

      response_hash[:data] = {}
    end

    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)
  end


  # Handle exceptions gracefully so that no exception goes unhandled.
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def handle_exceptions_gracefully

    begin

      yield

    rescue => se

      Rails.logger.error("Exception in API: #{se.message}")
      ApplicationMailer.notify(
          body: {exception: {message: se.message, backtrace: se.backtrace}},
          data: {
              'params' => params
          },
          subject: 'Exception in API'
      ).deliver

      r = Result::Base.exception(
          se,
          {
              error: 'swr',
              error_message: 'Something Went Wrong',
              data: params
          }
      )
      render_api_response(r)

    end

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

end
