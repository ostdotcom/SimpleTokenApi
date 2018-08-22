class Web::Admin::ConfiguratorController < Web::Admin::BaseController

  before_action only: [:publish_entity_group, :fetch_published_version] do
    authenticate_request(true)
  end

  skip_before_action :sanitize_params, only: [:update_entity_draft]

  before_action :validate_configurator_settings, except: [:fetch_published_version, :index]

  include ::Util::ResultHelper


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
    params[:form_data] = hashify_params_recursively(params)
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

  # Get user detail for opening kyc page and dashboard in preview mode
  #
  # * Author: Pankaj
  # * Date: 16/08/2018
  # * Reviewed By:
  #
  def preview_entity_draft
    service_response = AdminManagement::CmsConfigurator::PreviewEntityDraft.new(params).perform
    render_api_response(service_response)
  end

  private

  # Validate configurator settings of client
  #
  # * Author: Pankaj
  # * Date: 22/08/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate_configurator_settings
    client = Client.get_from_memcache(params[:client_id])
    if !client.is_web_host_setup_done?
      delete_cookie(GlobalConstant::Cookie.admin_cookie_name)
      service_response = error_with_data(
          "Unauthorized access",
          "Client don't have configurator access.",
          "Client don't have configurator access.",
          GlobalConstant::ErrorAction.default,
          {}
      )
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

end
