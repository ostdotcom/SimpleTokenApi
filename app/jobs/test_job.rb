class TestJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_low_priority_queue

  # Perform method that will be called on job start
  #
  # * Author: Bala
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)
    Rails.logger.info "Worker started processing ------ params: #{params.inspect}"
  end

end
