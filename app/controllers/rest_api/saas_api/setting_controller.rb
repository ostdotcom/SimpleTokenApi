class RestApi::SaasApi::SettingController < RestApi::SaasApi::BaseController

  before_action only: [:get_published_draft] do
    authenticate_request(true)
  end

  # Get Published Draft
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def get_published_draft
    service_response = AdminManagement::CmsConfigurator::GetPublishedDraft.new(params).perform
    render_api_response(service_response)
  end

end
