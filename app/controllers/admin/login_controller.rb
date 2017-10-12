class Admin::LoginController < Admin::BaseController

  before_action :validate_cookie, except: [
    :password_auth,
    :multifactor_auth
  ]

  # Password auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def password_auth

    service_response = AdminManagement::Login::PasswordAuth.new(
      params.merge(browser_user_agent: http_user_agent)
    ).perform

    if service_response.success?
      # Set cookie
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
        value: service_response.data[:single_auth_cookie_value],
        expires: GlobalConstant::Cookie.single_auth_expiry.from_now,
        domain: :all
      }
      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)

  end

  # Multifactor auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def multifactor_auth

    service_response = AdminManagement::Login::MultifactorAuth.new(
      params.merge({
                     single_auth_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
                     browser_user_agent: http_user_agent
                   })
    ).perform

    if service_response.success?
      # Set cookie
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
        value: service_response.data[:double_auth_cookie_value],
        expires: GlobalConstant::Cookie.double_auth_expiry.from_now,
        domain: :all
      }
      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)

  end

end