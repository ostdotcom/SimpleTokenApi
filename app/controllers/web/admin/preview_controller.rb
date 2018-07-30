class Web::Admin::PreviewController < Web::Admin::BaseController

  before_action :authenticate_request

  # Get logged in user details
  #
  # * Author: Aman
  # * Date: 09/02/2018
  # * Reviewed By:
  #
  def client_detail
    service_response = UserManagement::GetClientDetail.new(params).perform
    render_api_response(service_response)
  end

end
