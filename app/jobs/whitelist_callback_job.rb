class WhitelistCallbackJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Aman
  # * Date: 11/11/2017
  # * Reviewed By:
  #
  def perform(params)
    WhitelistManagement::ProcessAndRecordEvent.new(params).perform
  end

end
