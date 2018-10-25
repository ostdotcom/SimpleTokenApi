class InvalidWebhookJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def perform(params)

    init_params(params)

    set_not_valid_status_for_deleted_webhook

  end

  private

  # Init params
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def init_params(params)
    @client_id = params[:client_id]
    @client_webhook_setting_id = params[:client_webhook_setting_id]

    @webhook_send_logs = nil
  end

  # Set Not Valid Status For Deleted Webhook
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  # Sets @webhook_send_logs
  #
  #
  def set_not_valid_status_for_deleted_webhook
    WebhookSendLog.to_be_processed.where('lock_id is null').
        where(client_id: @client_id, client_webhook_setting_id: @client_webhook_setting_id)
        .update_all(status: GlobalConstant::WebhookSendLog.not_valid_status, updated_at: Time.now.to_s(:db))
  end

end
