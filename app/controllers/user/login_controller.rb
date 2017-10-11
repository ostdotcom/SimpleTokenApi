class User::LoginController < ApiController

  before_action :validate_cookie, except: [
    :sign_up,
    :login
  ]

  # Sign up
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def sign_up
    service_response = UserManagement::SignUp.new(params).perform

    if service_response.success?
      cookie_value = service_response.data.delete(:cookie_value)
      cookies[GlobalConstant::Cookie.user_cookie_name.to_sym] = {
        value: cookie_value,
        expires: GlobalConstant::Cookie.default_expiry.from_now,
        domain: :all
      }
    end

    render_api_response(service_response)
  end

  def login

  end

end
