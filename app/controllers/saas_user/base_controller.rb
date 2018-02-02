class SaasUser::BaseController < WebController

  before_action :authenticate_client_host

  before_action :authenticate_request

  private

  # Validate cookie
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  def authenticate_client_host
    service_response = UserManagement::VerifyClientHost.new(domain: request.domain).perform

    if service_response.success?
      params[:client_id] = service_response.data[:client_id]
      service_response.data = {}
    else
      # Set 401 header
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def authenticate_request
    service_response = UserManagement::VerifyCookie.new(
        cookie_value: cookies[GlobalConstant::Cookie.user_cookie_name.to_sym],
        browser_user_agent: http_user_agent
    ).perform

    if service_response.success?
      # Update Cookie, if required
      extended_cookie_value = service_response.data[:extended_cookie_value]
      set_cookie(
          GlobalConstant::Cookie.user_cookie_name,
          extended_cookie_value,
          GlobalConstant::Cookie.user_expiry.from_now
      ) if extended_cookie_value.present?

      # Set user id
      params[:user_id] = service_response.data[:user_id]

      # Remove sensitive data
      service_response.data = {}
    else
      # Clear cookie
      delete_cookie(GlobalConstant::Cookie.user_cookie_name)
      # Set 401 header
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

  # Merge Utm Parameter in params
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def merge_utm_to_params
    cookie_value = Oj.load(cookies[GlobalConstant::Cookie.utm_cookie_name.to_sym], mode: :strict) rescue {}
    params.merge!('utm_params' => cookie_value)
  end

end