class User::HomeController < User::BaseController

  skip_before_action :authenticate_request

  #
  # * Author: Aman
  # * Date: 18/01/2018
  # * Reviewed By:
  #
  def contact_us
    service_response = UserManagement::ContactUs.new(params).perform
    render_api_response(service_response)
  end

end
