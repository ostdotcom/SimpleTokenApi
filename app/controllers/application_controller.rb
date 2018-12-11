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
                               api_error_code: 'resource_not_found',
                               error: 'ac_1'
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
    response_hash = format_api_response(response_hash)
    http_status_code = response_hash.delete(:http_code)

    if !service_response.success? # && !Rails.env.development?

      #TODO: Check if email is to sent for invalid kyc submission
      # ApplicationMailer.notify(
      #   body: {},
      #   data: {
      #     response_hash: response_hash
      #   },
      #   subject: 'Error in KYC submit API'
      # ).deliver if params[:action] == 'kyc_submit' && params[:controller] == 'web/saas_user/token_sale'

      response_hash.delete(:data)
    end
    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)
  end

  # Format response if needed
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_api_response(response_hash)
    if response_hash[:err].present?
      response_hash[:err].delete(:error_extra_info)
      response_hash[:err].delete(:web_msg)
    end

    response_hash
  end

  # Sanitize and reformat Error response for Web
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def reformat_as_old_response(response_hash)
    # If request is from web then reformat data as per FE requirements
    # sanitizing out error and data. only display_text and display_heading are allowed to be sent to FE.
    if response_hash[:err].present?
      err = response_hash.delete(:err) || {}
      err_code_for_web =  err[:code]
      err_code_for_web = GlobalConstant::ErrorCode.error_code_for_http_code(response_hash[:http_code]) if err_code_for_web.blank?
      err_data = {}
      # puts err[:error_data].inspect
      err[:error_data].each {|ed| err_data[ed[:parameter]] = ed[:msg]} if err[:error_data].present?
      response_hash[:err] = {
          display_text: err[:web_msg] || err[:msg].to_s,
          display_heading: "Error",
          error_data: err_data,
          internal_id: err[:internal_id],
          code: err_code_for_web
      }
      response_hash[:err].merge!(error_extra_info: err[:error_extra_info]) if err[:error_extra_info].present?
    end
    response_hash[:http_code] = GlobalConstant::ErrorCode.ok if GlobalConstant::ErrorCode.http_codes_for_web.exclude?(response_hash[:http_code])
    response_hash
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


      r = Result::Base.error({
                                 api_error_code: 'internal_server_error',
                                 error: 'swr',
                                 data: params
                             })
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
