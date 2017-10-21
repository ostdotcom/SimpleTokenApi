class ApiController < ApplicationController

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

  before_action :validate_cookie

  handle_me

  private

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def validate_cookie
    fail 'Sub-class to implement.'
  end

  # Handle exceptions gracefully so that no exception goes unhandled.
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def handle_exceptions_gracefully

    begin

      yield

    rescue => se

      Rails.logger.error("Exception in API: #{se.message}")
      ApplicationMailer.notify(
          body: {exception: {message: se.message, backtrace: se.backtrace}},
          data: {
              'params' => params
          },
          subject: 'Exception in API'
      ).deliver

      r = Result::Base.exception(
        se,
        {
          error: 'swr',
          error_message: 'Something Went Wrong',
          data: params
        }
      )
      render_api_response(r)

    end

  end

end
