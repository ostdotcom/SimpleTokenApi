class Web::Admin::ClientController < Web::Admin::BaseController
  before_action :authenticate_request

  # get client profile details
  #
  # * Author: Tejas
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def get_profile_detail
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

  # get Auto Approve Setting
  #
  # * Author: Aniket/Tejas
  # * Date: 03/07/2018
  # * Reviewed By:
  #
  def get_auto_approve_setting
    service_response = ClientManagement::GetAutoApproveSetting.new(params).perform
    render_api_response(service_response)
  end

  # Get Sale Setting
  #
  # * Author: Tejas
  # * Date: 27/08/2018
  # * Reviewed By:
  #
  def get_sale_setting
    service_response = ClientManagement::GetSaleSetting.new(params).perform
    render_api_response(service_response)
  end

  # Get Country Setting
  #
  # * Author: Tejas
  # * Date: 27/08/2018
  # * Reviewed By:
  #
  def get_country_setting
    service_response = ClientManagement::GetCountrySetting.new(params).perform
    render_api_response(service_response)
  end

end