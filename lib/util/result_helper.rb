module Util

  module ResultHelper

    # All methods of this module are common short hands used for

    # Success
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def success
      success_with_data({})
    end

    # Success with data
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Hash] data (mandatory) - data to be sent in the response
    #
    # @return [Result::Base]
    #
    def success_with_data(data)
      # Allow only Hash data to pass ahead
      data = {} unless Util::CommonValidator.is_a_hash?(data)

      Result::Base.success({
                               data: data
                           })
    end

    # Error with Action
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] code (mandatory) - error code
    # @param [String] msg (mandatory) - error message
    # @param [String] display_heading (optional) - display heading
    # @param [String] display_text (mandatory) - error display text
    # @param [String] action (mandatory) - error action
    # @param [Hash] data (mandatory) - error data
    #
    # @return [Result::Base]
    #
    def error_with_action_and_data(code, msg, display_text, action, data, display_heading = 'Error')
      Result::Base.error(
          {
              error: code,
              error_message: msg,
              error_action: action,
              error_display_text: display_text,
              error_display_heading: display_heading,
              data: data
          }
      )
    end

    # Exception with action and data
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Exception] e (mandatory) - Exception object
    # @param [String] code (mandatory) - error code
    # @param [String] msg (mandatory) - error message
    # @param [String] display_text (mandatory) - display text
    # @param [String] action (mandatory) - action
    # @param [Hash] data (mandatory) - error data
    # @param [String] display_heading (Optional) - display heading
    #
    # @return [Result::Base]
    #
    def exception_with_action_and_data(e, code, msg, display_text, action, data, display_heading = 'Error')
      Result::Base.exception(
        e, {
        error: code,
        error_message: msg,
        error_action: action,
        error_display_text: display_text,
        error_display_heading: display_heading,
        data: data
      })
    end

  end

end