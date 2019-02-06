class Web::WebController < ApplicationController

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception

  include CsrfTokenConcern

  [
      ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  before_action :merge_source_of_request

  # merge into params the source of the request to be used in services for webhooks
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def merge_source_of_request
    params.merge!(source_of_request: GlobalConstant::Event.web_source)
  end

  # Verify recaptcha
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def verify_recaptcha
    service_response = Recaptcha::Verify.new({
                                                 'response' => params['g-recaptcha-response'].to_s,
                                                 'remoteip' => request.remote_ip.to_s
                                             }).perform

    Rails.logger.info('---- Recaptcha::Verify done')

    unless service_response.success?
      render_api_response(service_response)
    end

    Rails.logger.info('---- check_recaptcha_before_verification done')

  end

  # Delete the given cookie
  #
  # * Author: Aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def delete_cookie(cookie_name)
    cookies.delete(cookie_name.to_sym, domain: request.host, secure: !(Rails.env.development? || Rails.env.staging?), same_site: :strict)
  end

  # Set the given cookie
  #
  # * Author: Aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def set_cookie(cookie_name, value, expires, encrypt=false)
    cookie_obj = (encrypt == true) ? cookies.encrypted : cookies
    cookie_obj[cookie_name.to_sym] = {
        value: value,
        expires: expires,
        domain: request.host,
        http_only: true,
        secure: !(Rails.env.development? || Rails.env.staging?),
        same_site: :strict
    }
  end

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def authenticate_request
    fail 'Sub-class to implement.'
  end

  # Merge Utm Parameter in params
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def merge_utm_to_params
    cookie_value = Oj.load(cookies[GlobalConstant::Cookie.utm_cookie_name.to_sym], mode: :strict) rescue {}
    params.merge!('utm_params' => cookie_value)
  end

  # Sanitize and reformat Error response as per old response
  # NOT APPLICABLE for new services V2 Onwards
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_api_response(response_hash)
    reformat_as_old_response(response_hash)
  end

end
