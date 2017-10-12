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
      browser_user_agent: request.env['HTTP_USER_AGENT'].to_s
    ).perform

    if service_response.success?
      params[:user_id] = service_response.data[:user_id]
    else
      render_api_response(service_response)
    end
  end

end