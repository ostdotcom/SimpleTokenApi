class User::LoginController < User::BaseController

  before_action :validate_cookie, except: [
                                    :sign_up,
                                    :login,
                                    :send_reset_password_link,
                                    :reset_password
                                ]

  # Sign up
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def sign_up
    service_response = UserManagement::SignUp.new(
      params.merge(browser_user_agent: http_user_agent)
    ).perform

    if service_response.success?
      # NOTE: delete cookie value from data
      cookie_value = service_response.data.delete(:cookie_value)
      cookies[GlobalConstant::Cookie.user_cookie_name.to_sym] = {
          value: cookie_value,
          expires: GlobalConstant::Cookie.double_auth_expiry.from_now,
          domain: :all
      }
    end

    render_api_response(service_response)
  end

  # login
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def login
    service_response = UserManagement::Login.new(
      params.merge(browser_user_agent: http_user_agent)
    ).perform

    if service_response.success?
      cookie_value = service_response.data.delete(:cookie_value)
      cookies[GlobalConstant::Cookie.user_cookie_name.to_sym] = {
        value: cookie_value,
        expires: GlobalConstant::Cookie.double_auth_expiry.from_now,
        domain: :all
      }
    end

    render_api_response(service_response)
  end

  # Send Reset Password Link
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def send_reset_password_link
    service_response = UserManagement::SendResetPasswordLink.new(params).perform
    render_api_response(service_response)
  end

  # Reset Password
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def reset_password
    service_response = UserManagement::ResetPassword.new(params).perform
    render_api_response(service_response)
  end

end
