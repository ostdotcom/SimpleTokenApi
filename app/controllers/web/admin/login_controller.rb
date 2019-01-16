class Web::Admin::LoginController < Web::Admin::BaseController

  before_action :authenticate_request, except: [
      :password_auth,
      :get_ga_url,
      :multifactor_auth,
      :send_admin_reset_password_link,
      :admin_reset_password,
      :invite_detail,
      :activate_invited_admin,
      :logout
  ]
  before_action :verify_recaptcha, only: [:password_auth]

  # Password auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def password_auth

    service_response = AdminManagement::Login::PasswordAuth.new(
        params.merge(browser_user_agent: http_user_agent)
    ).perform

    if service_response.success?
      # Set cookie
      set_cookie(
          GlobalConstant::Cookie.admin_cookie_name,
          service_response.data[:single_auth_cookie_value],
          GlobalConstant::Cookie.single_auth_expiry.from_now
      )

      # Remove sensitive data
      service_response.data = {}
    end

    render_api_response(service_response)

  end

  # Logout admin
  #
  # * Author: Aniket
  # * Date: 21/09/2018
  # * Reviewed By:
  #
  def logout
    params = {
        cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
        browser_user_agent: http_user_agent
    }

    AdminManagement::Logout.new(params).perform

    delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
    redirect_to "/admin/login", status: GlobalConstant::ErrorCode.permanent_redirect
  end

  # get Admins Ga AUTH QR code on first time login
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def get_ga_url
    service_response = AdminManagement::Login::Multifactor::GetGaUrl.new(
        params.merge({
                         single_auth_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
                         browser_user_agent: http_user_agent
                     })).perform
    render_api_response(service_response)
  end

  # Multifactor auth
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def multifactor_auth

    service_response = AdminManagement::Login::Multifactor::Authenticate.new(
        params.merge({
                         single_auth_cookie_value: cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym],
                         browser_user_agent: http_user_agent
                     })
    ).perform

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

  # Send Admin Reset Password Link
  #
  # * Author: Pankaj
  # * Date: 30/04/2018
  # * Reviewed By:
  #
  def send_admin_reset_password_link
    service_response = AdminManagement::Login::SendAdminResetPasswordLink.new(params).perform
    render_api_response(service_response)
  end

  # Reset Password
  #
  # * Author: Pankaj
  # * Date: 30/04/2018
  # * Reviewed By:
  #
  def admin_reset_password
    service_response = AdminManagement::Login::AdminResetPassword.new(params).perform
    render_api_response(service_response)
  end

  # Invite Password load page
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def invite_detail
    service_response = AdminManagement::AdminUser::GetInviteDetail.new(params).perform
    render_api_response(service_response)
  end

  # Activate Invited admin user
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def activate_invited_admin
    service_response = AdminManagement::AdminUser::ActivateInvitedAdmin.new(params).perform
    render_api_response(service_response)
  end


  # Get Terms Of Use
  #
  # * Author: Tejas
  # * Date: 15/01/2019
  # * Reviewed By:
  #
  def get_terms_of_use
    service_response = AdminManagement::Login::TermsOfUse::GetTermsOfUse.new(params).perform
    render_api_response(service_response)
  end

  # Update Terms Of Use
  #
  # * Author: Tejas
  # * Date: 15/01/2019
  # * Reviewed By:
  #
  def update_terms_of_use
    service_response = AdminManagement::Login::TermsOfUse::UpdateTermsOfUse.new(params).perform
    render_api_response(service_response)
  end

end