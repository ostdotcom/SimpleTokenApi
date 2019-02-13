class Web::Admin::BaseController < Web::WebController

  include Util::ResultHelper

  before_action :authenticate_request

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def authenticate_request(options = {is_super_admin_role: false, validate_terms_of_use: true})

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

  # Check if single auth logged in admin and redirect to required page
  #
  # * Author: Aman
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  def is_single_auth_logged_in
    auth_cookie = cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym]
    return if auth_cookie.blank?

    service_response = AdminManagement::VerifyCookie::SingleAuth.new(
        cookie_value: auth_cookie,
        browser_user_agent: http_user_agent
    ).perform


    if service_response.success?
      err = error_with_internal_code('c_w_a_bc_vsali_1',
                                     'Redirecting',
                                     GlobalConstant::ErrorCode.temporary_redirect,
                                     {},
                                     {},
                                     {}
      )

      err.set_error_extra_info({redirect_url: GlobalConstant::WebUrls.multifactor_auth})
      render_api_response(err) and return
    else
      # delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
    end

  end

  # Check if double_auth logged in admin and redirect to required page
  #
  # * Author: Aman
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  def is_double_auth_logged_in
    auth_cookie = cookies[GlobalConstant::Cookie.admin_cookie_name.to_sym]
    return if auth_cookie.blank?

    service_response = AdminManagement::VerifyCookie::DoubleAuth.new(
        cookie_value: auth_cookie,
        browser_user_agent: http_user_agent,
        options: {is_super_admin_role: false, validate_terms_of_use: true}
    ).perform

    if service_response.http_code == GlobalConstant::ErrorCode.temporary_redirect
      render_api_response(service_response)
    elsif service_response.success?
      err = error_with_internal_code('c_w_a_bc_vdali_1',
                                     'Redirecting',
                                     GlobalConstant::ErrorCode.temporary_redirect,
                                     {},
                                     {},
                                     {}
      )
      err.set_error_extra_info({redirect_url: GlobalConstant::WebUrls.admin_dashboard})
      render_api_response(err)
    else
      # delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
    end
  end


end