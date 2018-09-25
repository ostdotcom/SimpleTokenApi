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
    # @param [String] message (mandatory) - error message
    # @param [String] display_text (mandatory) - error display text
    # @param [String] action (mandatory) - error action
    # @param [Hash] data (mandatory) - data
    # @param [Hash] error_data (mandatory) - error data
    #
    # @return [Result::Base]
    #
    def error_with_data(internal_code, message, display_text, action, data, error_data = {})
      Result::Base.error(
          {
              error: internal_code,
              error_message: message,
              error_data: error_data,
              error_action: action,
              error_display_text: display_text,
              data: data
          }
      )
    end

    # Error with Identifier
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @param [String] api_error_code (mandatory) - Error code for sending Api response
    # @param [String] internal_code (mandatory) - Internal error code
    # @param [Array] params_error_identifiers (Optional) - Group of error codes to send in Api response
    #
    # @return [Result::Base]
    #
    def error_with_identifier(api_error_code, internal_code, params_error_identifiers = [])
      Result::Base.error(
          {
              api_error_code: api_error_code,
              error: internal_code,
              params_error_identifiers: params_error_identifiers
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
    # @param [String] message (mandatory) - error message
    # @param [String] display_text (mandatory) - display text
    # @param [String] action (mandatory) - action
    # @param [Hash] data (mandatory) - error data
    #
    # @return [Result::Base]
    #
    def exception_with_data(e, code, message, display_text, action, data)
      Result::Base.exception(
        e, {
        error: code,
        error_message: message,
        error_action: action,
        error_display_text: display_text,
        data: data
      })
    end

    # Current Time
    #
    # * Author: Sunil Khedar
    # * Date: 19/10/2017
    # * Reviewed By: Kedar
    #
    def current_time
      @c_t ||= Time.now
    end

    # Current Time Stamp
    #
    # * Author: Sunil Khedar
    # * Date: 19/10/2017
    # * Reviewed By: Kedar
    #
    def current_timestamp
      @c_tstmp ||= current_time.to_i
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
    def success_result(data)
      # Allow only Hash data to pass ahead
      data = {} unless Util::CommonValidator.is_a_hash?(data)

      Result::Base.success({
                               data: data
                           })
    end

    # Error with internal code
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [String] code (mandatory) - error code
    # @param [String] msg (mandatory) - error message
    # @param [Integer] internal_code (mandatory) - internal code, on which conditions can be made
    # @param [String] data (optional) - error data
    # @param [Hash] extended_data[:tracking_data] (optional) - tracking data to be sent in the response
    # @param [Hash] extended_data[:segmentation_data] (optional) - segmentation data to be sent in the response
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def error_with_internal_code(code, msg, internal_code, data = {}, error_data = {}, error_display_text= '')

      Result::Base.error(
          {
              error: code,
              error_message: msg,
              error_display_text: error_display_text || msg,
              data: data,
              http_code: internal_code,
              error_data: error_data
          })
    end

    # Exception with internal code
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Exception] e (mandatory) - Exception object
    # @param [String] code (mandatory) - error code
    # @param [String] msg (mandatory) - error message
    # @param [Integer] internal_code (mandatory) - internal code, on which conditions can be made
    # @param [String] data (optional) - error data
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def exception_with_internal_code(e, code, msg, internal_code, data = {})

      Result::Base.exception(
          e, {
          error: code,
          error_message: msg,
          data: data,
          http_code: internal_code
      }
      )
    end

  end

end