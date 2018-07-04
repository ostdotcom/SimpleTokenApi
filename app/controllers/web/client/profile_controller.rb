class Web::Client::ProfileController < Web::Admin::BaseController
  before_action :authenticate_request


  # get client details
  #
  # * Author: Tejas
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def get_detail
    service_response = ClientManagement::GetProfileDetails.new(params).perform
    render_api_response(service_response)
  end

  # get Developer Detail
  #
  # * Author: Aniket
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def get_developer_detail
    service_response = ClientManagement::DeveloperDetail.new(params).perform
    render_api_response(service_response)
  end

  # get Artifical Intellignce Setting
  #
  # * Author: Aniket/Tejas
  # * Date: 03/07/2018
  # * Reviewed By:
  #
  def get_artifical_intellignce_setting
    service_response = ClientManagement::GetAutoApproveSetting.new(params).perform
    render_api_response(service_response)
  end

  # Update Artifical Intellignce Setting
  #
  # * Author: Aniket
  # * Date: 03/07/2018
  # * Reviewed By:
  #
  def update_artifical_intellignce_setting
    service_response = ClientManagement::UpdateAutoApproveSetting.new(params).perform
    render_api_response(service_response)
  end

end