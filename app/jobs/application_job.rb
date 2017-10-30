class ApplicationJob < ActiveJob::Base

  require 'benchmark'

  # checks if time taken > threshold and logs
  #
  # * Author: Bala
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  around_perform do |job, block|
    begin
      Rails.logger.info "Worker started processing job (#{job.job_id})"
      execution_time = Benchmark.realtime do
        block.call
      end
      monitor_execution_time(job, execution_time)
      Rails.logger.info "Worker completed job (#{job.job_id})"
    rescue StandardError => se
      Rails.logger.info "Worker got exception in job #{job.job_id}) msg : #{se.message} trace : #{se.backtrace}"
      ApplicationMailer.notify(
        body: {exception: {message: se.message, backtrace: se.backtrace}},
        data: job.arguments,
        subject: "Exception in #{self.class}"
      ).deliver
      raise se
    end
  end

  # checks if time taken > threshold and logs
  #
  # * Author: Bala
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def monitor_execution_time(job, execution_time)
    threshold_time = 0.04
    if execution_time > threshold_time
      Rails.logger.info "slow_job_log  -- #{job.job_id}  --  resque_task  --  #{job.class}  --  #{threshold_time}"
    end
  end

end
