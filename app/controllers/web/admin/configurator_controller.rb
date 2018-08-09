class Web::Admin::ConfiguratorController < Web::Admin::BaseController

  before_action :authenticate_request

  # Get upload params for client logo and favicon configuration
  #
  # * Author: Pankaj
  # * Date: 06/08/2018
  # * Reviewed By:
  #
  def get_image_upload_params
    service_response = UserManagement::GetUploadParams.new(params).perform
    render_api_response(service_response)
  end

end