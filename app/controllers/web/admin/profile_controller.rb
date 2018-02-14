class Web::Admin::ProfileController < Web::Admin::BaseController

  # Change Password
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def change_password
    service_response = AdminManagement::Profile::ChangePassword.new(params.merge(browser_user_agent: http_user_agent)).perform

    if service_response.success?
      # Set cookie
      set_cookie(
          GlobalConstant::Cookie.admin_cookie_name,
          service_response.data[:double_auth_cookie_value],
          GlobalConstant::Cookie.double_auth_expiry.from_now
      )

      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)
  end

  # get client details
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def get_detail
    service_response = AdminManagement::Profile::GetDetail.new(params).perform
    render_api_response(service_response)
  end

end