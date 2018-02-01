class Admin::LoginController < Admin::BaseController

  before_action :authenticate_request, except: [
                                         :password_auth,
                                         :get_ga_url,
                                         :multifactor_auth
                                     ]
  before_action :verify_recaptcha, only: [:password_auth]

  # Password auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def password_auth

    service_response = AdminManagement::Login::PasswordAuth.new(
        params.merge(browser_user_agent: http_user_agent)
    ).perform

    if service_response.success?
      # Set cookie
      set_cookie(
          GlobalConstant::Cookie.admin_cookie_name,
          service_response.data[:single_auth_cookie_value],
          GlobalConstant::Cookie.single_auth_expiry.from_now
      )

      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)

  end

  # get Admins Ga AUTH QR code on first time login
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def get_ga_url
    service_response = AdminManagement::Login::Multifactor::GetGaUrl.new(
        params.merge({
                         single_auth_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
                         browser_user_agent: http_user_agent
                     })).perform
    render_api_response(service_response)
  end

  # Multifactor auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def multifactor_auth

    service_response = AdminManagement::Login::Multifactor::Authenticate.new(
        params.merge({
                         single_auth_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
                         browser_user_agent: http_user_agent
                     })
    ).perform

    if service_response.success?
      # Set cookie
      set_cookie(
          GlobalConstant::Cookie.admin_cookie_name,
          service_response.data[:double_auth_cookie_value],
          GlobalConstant::Cookie.double_auth_expiry.from_now
      )
      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)

  end

end