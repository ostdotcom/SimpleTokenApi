class Web::Admin::WebhookController < Web::Admin::BaseController

  before_action do
    authenticate_request(true)
  end

  # Get Webhook Detail
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def get_webhook_detail
    service_response = ClientManagement::GetWebhookDetail.new(params).perform
    render_api_response(service_response)
  end

  # Create Webhook
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def create_webhook
    service_response = ClientManagement::Webhook::Create.new(params).perform
    render_api_response(service_response)
  end

  # Update Webhook
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def update_webhook
    service_response = ClientManagement::Webhook::Update.new(params).perform
    render_api_response(service_response)
  end

  # Reset Secret Key
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def reset_secret_key
    service_response = ClientManagement::WebhookSetting::ResetSecretKey.new(params).perform
    render_api_response(service_response)
  end

  # Reset Secret Key
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def test
    service_response = ClientManagement::WebhookSetting::Test.new(params).perform
    render_api_response(service_response)
  end

  # Delete Webhook
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def delete_webhook
    service_response = ClientManagement::WebhookSetting::DeleteWebhook.new(params).perform
    render_api_response(service_response)
  end

end