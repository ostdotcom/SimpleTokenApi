class AdminActivityLoggerJob < ApplicationJob
  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # perform
  #
  # * Author: Aniket
  # * Date: 10/10/2018
  # * Reviewed By:
  #
  def perform(params)
      populate(params)
  end

  # populate
  #
  # * Author: Aniket
  # * Date: 10/10/2018
  # * Reviewed By:
  #
  def populate(params)
    begin
     AdminActivityChangeLogger.create!(params)
    rescue ActiveRecord::StatementInvalid => e
      if (/Data too long for column.*/ =~ e.cause.to_s).present?
        Rails.logger.info "logger entry failed. #{e.message}"
        ApplicationMailer.notify(
            body: {exception: {message: e.message, backtrace: e.backtrace}},
            data: params,
            subject: "Exception in ActivityChangeLogger. Data too long for column."
        ).deliver
      end
    rescue => e
      puts "Exception is #{e.inspect} and backtrace #{e.backtrace}"
        ApplicationMailer.notify(
            body: {exception: {message: e.message, backtrace: e.backtrace}},
            data: params,
            subject: "Exception in ActivityChangeLogger."
        ).deliver
    end
  end

end