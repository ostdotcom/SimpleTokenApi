class Web::SaasUser::BaseController < Web::WebController

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
    service_response = UserManagement::VerifyClientHost.new(domain: request.host).perform

    if service_response.success?
      params[:client_id] = service_response.data[:client_id]
      params[:client] = service_response.data[:client]
      service_response.data = {}
    else
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
        client: params[:client],
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
      render_api_response(service_response)
    end
  end

end