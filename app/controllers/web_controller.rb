class WebController < ApplicationController

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception

  include CsrfTokenConcern

  [
      ActionController::Cookies
  ].each do |mdl|
    include mdl
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
    # cookies.delete(cookie_name.to_sym, domain: :all, secure: !Rails.env.development?, same_site: :strict)
    cookies.delete(cookie_name.to_sym, domain: request.host, secure: !Rails.env.development?, same_site: :strict)
  end

  # Set the given cookie
  #
  # * Author: Aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def set_cookie(cookie_name, value, expires)
    cookies[cookie_name.to_sym] = {
        value: value,
        expires: expires,
        domain: request.host,
        http_only: true,
        secure: !Rails.env.development?,
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

end
