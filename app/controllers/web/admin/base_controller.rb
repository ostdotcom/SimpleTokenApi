class Web::Admin::BaseController < Web::WebController

  before_action :authenticate_request

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def authenticate_request(options={is_super_admin_role: false, validate_terms_of_use: true})

    service_response = AdminManagement::VerifyCookie::DoubleAuth.new(
        cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
        browser_user_agent: http_user_agent,
        options: options
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
      params[:client_id] = service_response.data[:client_id]

      # Remove sensitive data
      service_response.data = {}
    else
      if service_response.http_code == GlobalConstant::ErrorCode.unauthorized_access
        delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
      end
      render_api_response(service_response)
    end

  end

end