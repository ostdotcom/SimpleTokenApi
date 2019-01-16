class Web::Admin::ProfileController < Web::Admin::BaseController

  before_action :authenticate_request, except: [:get_terms_of_use, :update_terms_of_use]

  before_action only: [:get_terms_of_use, :update_terms_of_use] do
    authenticate_request({validate_terms_of_use: false})
  end

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

  # Get Terms Of Use
  #
  # * Author: Tejas
  # * Date: 15/01/2019
  # * Reviewed By:
  #
  def get_terms_of_use
    service_response = AdminManagement::Profile::GetTermsOfUse.new(params).perform
    render_api_response(service_response)
  end

  # Update Terms Of Use
  #
  # * Author: Tejas
  # * Date: 15/01/2019
  # * Reviewed By:
  #
  def update_terms_of_use
    service_response = AdminManagement::Profile::UpdateTermsOfUse.new(params).perform
    render_api_response(service_response)
  end



end