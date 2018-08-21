class Web::Admin::ConfiguratorController < Web::Admin::BaseController

  before_action only: [:publish_entity_group, :fetch_published_version] do
    authenticate_request(true)
  end


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
    params[:form_data] = HashWithIndifferentAccess.new(params.to_unsafe_hash)
    service_response = AdminManagement::CmsConfigurator::UpdateEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  # Get Draft Config
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def get_draft_config
    service_response = AdminManagement::CmsConfigurator::GetEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  # Reset Entity Draft
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def reset_entity_draft
    service_response = AdminManagement::CmsConfigurator::ResetEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  # Publish Entity Group
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def publish_entity_group
    service_response = AdminManagement::CmsConfigurator::PublishEntityGroup.new(params).perform
    render_api_response(service_response)
  end

  # Create Entity Group
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def create_entity_group
    service_response = AdminManagement::CmsConfigurator::CreateEntityGroup.new(params).perform
    render_api_response(service_response)
  end

  # Index
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def index
    service_response = AdminManagement::CmsConfigurator::Index.new(params).perform
    render_api_response(service_response)
  end

  # Fetch Published Version
  #
  # * Author: Tejas
  # * Date: 14/08/2018
  # * Reviewed By:
  #
  def fetch_published_version
    service_response = AdminManagement::CmsConfigurator::FetchPublishedVersion.new(params).perform
    render_api_response(service_response)
  end

end
