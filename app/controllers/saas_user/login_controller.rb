class SaasUser::LoginController < SaasUser::BaseController

  prepend_before_action :merge_utm_to_params, only: [:sign_up]

  skip_before_action :authenticate_request

  before_action :verify_recaptcha, only: [:sign_up, :login]

  # Sign up
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def sign_up
    geo_ip_obj = Util::GeoIpUtil.new(ip_address: ip_address)
    geoip_country = geo_ip_obj.get_country_name.to_s.downcase

    service_response = UserManagement::SignUp.new(
        params.merge(
            browser_user_agent: http_user_agent,
            ip_address: ip_address,
            geoip_country: geoip_country
        )
    ).perform

    if service_response.success?
      # NOTE: delete cookie value from data
      cookie_value = service_response.data.delete(:cookie_value)
      set_cookie(
          GlobalConstant::Cookie.user_cookie_name,
          cookie_value,
          GlobalConstant::Cookie.user_expiry.from_now
      )
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
        params.merge(
            browser_user_agent: http_user_agent,
            ip_address: ip_address
        )
    ).perform

    if service_response.success?
      # NOTE: delete cookie value from data
      cookie_value = service_response.data.delete(:cookie_value)
      set_cookie(
          GlobalConstant::Cookie.user_cookie_name,
          cookie_value,
          GlobalConstant::Cookie.user_expiry.from_now
      )
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
