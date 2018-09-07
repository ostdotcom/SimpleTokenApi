class UpdateWhitelist < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Aniket
  # * Date: 07/08/2018
  # * Reviewed By:
  #
  def perform(params)
    OpsApi::Request::UpdateSubscription.new.perform(params)
  end

end
