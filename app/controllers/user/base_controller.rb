class User::BaseController < ApiController

  before_action :handle_blacklisted_ip

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def validate_cookie
    service_response = UserManagement::VerifyCookie.new(
        cookie_value: cookies[GlobalConstant::Cookie.user_cookie_name.to_sym],
        browser_user_agent: http_user_agent
    ).perform

    if service_response.success?
      # Update Cookie, if required
      extended_cookie_value = service_response.data[:extended_cookie_value]
      cookies[GlobalConstant::Cookie.user_cookie_name.to_sym] = {
          value: extended_cookie_value,
          expires: GlobalConstant::Cookie.double_auth_expiry.from_now,
          domain: :all
      } if extended_cookie_value.present?

      # Set user id
      params[:user_id] = service_response.data[:user_id]

      # Remove sensitive data
      service_response.data = {}
    else
      # Clear cookie
      cookies.delete(GlobalConstant::Cookie.user_cookie_name.to_sym, domain: :all)
      # Set 401 header
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

  # Validate ip of request
  #
  # * Author: Aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def handle_blacklisted_ip
    blacklisted_countries = ['china']
    return unless Util::GeoIpUtil.maxmind_file_exists?
    geo_ip_obj = Util::GeoIpUtil.new(ip_address: ip_address)
    return unless blacklisted_countries.include?(geo_ip_obj.get_country_name.to_s.downcase)

    service_response = Result::Base.error(
        {
            error: 'w_u_bc_1',
            error_message: 'Unauthorised Ip',
            error_data: {},
            error_action: GlobalConstant::ErrorAction.default,
            error_display_text: 'Unauthorised Ip',
            error_display_heading: 'Error',
            data: {}
        }
    )

    service_response.http_code = GlobalConstant::ErrorCode.forbidden
    render_api_response(service_response)
  end

end