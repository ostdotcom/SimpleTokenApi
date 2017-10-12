class User::LoginController < User::BaseController

  before_action :validate_cookie, except: [:sign_up, :login, :user_info]

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

  # Get logged in user details
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def user_info
    service_response = UserManagement::UserInfo.new(cookie_value: cookies[GlobalConstant::Cookie.user_cookie_name.to_sym], browser_user_agent: http_user_agent).perform
    render_api_response(service_response)
  end

  # Get logged in user details
  #
  # * Author: Kedar
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def get_upload_params
    service_response = UserManagement::GetUploadParams.new(params).perform
    render_api_response(service_response)
  end

end
