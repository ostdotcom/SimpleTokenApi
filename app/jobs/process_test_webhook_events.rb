class ProcessTestWebhookEvents < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Aman
  # * Date: 15/11/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def perform(params)
    Crons::Webhooks::TestSend.new(lock_id: params[:lock_id],
                                  client_webhook_setting_id: params[:client_webhook_setting_id],
                                  admin_id: params[:admin_id]).perform

  end

end

