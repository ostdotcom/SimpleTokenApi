class Web::Client::ProfileController < Web::Admin::BaseController
  before_action :authenticate_request


  # get client details
  #
  # * Author: Tejas
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def profile
    service_response = AdminManagement::Profile::GetDetail.new(params).perform
    render_api_response(service_response)
  end


end