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
      cookie_value = service_response.data.delete(:step1_cookie_value)
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
        value: cookie_value,
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
    puts "------------------------------------------"
    service_response = AdminManagement::Login::MultifactorAuth.new(
      params.merge(step_1_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym])
    ).perform

    if service_response.success?
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
        value: service_response.data[:step2_cookie_value],
        expires: GlobalConstant::Cookie.default_expiry.from_now,
        domain: :all
      }
    end

    render_api_response(service_response)
  end

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def validate_cookie
    service_response = AdminManagement::VerifyCookie.new(
      cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
      action: params[:action],
      controller: params[:controller]
    ).perform

    unless service_response.success?
      render_api_response(service_response)
    end
  end

end
