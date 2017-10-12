class TestJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :que1

  # Perform method that will be called on job start
  #
  # * Author: Bala
  # * Date: 11/10/2017
  # * Reviewed By:
  #
  def perform(params)
    Rails.logger.info "Worker started processing ------ params: #{params.inspect}"
  end

end
