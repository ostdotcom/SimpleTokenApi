class Admin::BaseController < ApiController

  before_action :validate_cookie

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def validate_cookie

    service_response = AdminManagement::VerifyCookie::DoubleAuth.new(
      cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym]
    ).perform

    if service_response.success?

      # Update Cookie
      cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym] = {
          value: service_response.data[:extended_cookie_value],
          expires: GlobalConstant::Cookie.double_auth_expiry.from_now,
          domain: :all
      } if service_response.data[:extended_cookie_value].present?

      @admin_id = service_response.data[:admin_id]

      # Remove sensitive data
      service_response.data = {}
    else
      cookies.delete(GlobalConstant::Cookie.admin_cookie_name.to_sym, domain: :all)
      render_api_response(service_response)
    end

  end

end