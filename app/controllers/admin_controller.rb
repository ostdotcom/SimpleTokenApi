class AdminController < ApiController

  before_action :validate_cookie, except: [
    :password_auth
  ]

  # Password auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def password_auth
    service_response = AdminManagement::Login::PasswordAuth.new(params).perform

    if service_response.success?
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
        value: service_response.data[:step1_cookie_value],
        expires: GlobalConstant::Cookie.default_expiry.from_now,
        domain: :all
      }
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

  end


end
