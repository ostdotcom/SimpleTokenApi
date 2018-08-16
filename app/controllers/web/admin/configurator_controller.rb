class Web::Admin::ConfiguratorController < Web::Admin::BaseController

  before_action :authenticate_request

  # Get upload params for client logo and favicon configuration
  #
  # * Author: Pankaj
  # * Date: 06/08/2018
  # * Reviewed By:
  #
  def get_image_upload_params
    service_response = AdminManagement::CmsConfigurator::GetUploadParams.new(params).perform
    render_api_response(service_response)
  end

  # Update configurator entity draft
  #
  # * Author: Aniket
  # * Date: 06/08/2018
  # * Reviewed By:
  #
  def update_entity_draft
    service_response = AdminManagement::CmsConfigurator::UpdateEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  def get_draft_config
    service_response = AdminManagement::CmsConfigurator::GetEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  def reset_user_draft
    service_response = AdminManagement::CmsConfigurator::ResetUserDraft.new(params).perform
    render_api_response(service_response)
  end

  def publish_user_draft
    service_response = AdminManagement::CmsConfigurator::PublishUserDraft.new(params).perform
    render_api_response(service_response)
  end

  def create_user_group
    service_response = AdminManagement::CmsConfigurator::CreateUserGroup.new(params).perform
    render_api_response(service_response)
  end

end
