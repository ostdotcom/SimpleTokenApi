class Web::Admin::UserPreviewController < Web::Admin::BaseController

  before_action :authenticate_request

  # Get client detail for opening login and registration preview
  #
  # * Author: Pankaj
  # * Date: 16/08/2018
  # * Reviewed By:
  #
  def client_detail
    service_response = UserManagement::GetClientDetail.new(params.merge(in_preview_mode: true)).perform
    render_api_response(service_response)
  end

  # Get user detail for opening kyc page and dashboard in preview mode
  #
  # * Author: Pankaj
  # * Date: 16/08/2018
  # * Reviewed By:
  #
  def dummy_user_preview
    service_response = UserManagement::PreviewDummyUser.new(params.merge!(in_preview_mode: true)).perform
    render_api_response(service_response)
  end

end
