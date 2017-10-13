class User::BaseController < ApiController

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
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

      params[:user_id] = service_response.data[:user_id]
      params[:user_token_sale_state] = service_response.data[:user_token_sale_state]

      # Remove sensitive data
      service_response.data = {}
    else
      cookies.delete(GlobalConstant::Cookie.user_cookie_name.to_sym, domain: :all)
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

end