class Admin::BaseController < ApiController

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def validate_cookie

    service_response = AdminManagement::VerifyCookie::DoubleAuth.new(
        cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
        browser_user_agent: http_user_agent
    ).perform

    if service_response.success?
      # Update Cookie, if required
      extended_cookie_value = service_response.data[:extended_cookie_value]
      set_cookie(
          GlobalConstant::Cookie.admin_cookie_name,
          extended_cookie_value,
          GlobalConstant::Cookie.double_auth_expiry.from_now
      ) if extended_cookie_value.present?

      params[:admin_id] = service_response.data[:admin_id]

      # Remove sensitive data
      service_response.data = {}
    else
      delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end

  end

end