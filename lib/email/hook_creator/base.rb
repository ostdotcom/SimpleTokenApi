module Email

  module HookCreator

    class Base

      include Util::ResultHelper

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Email::HookCreator::Base] returns an object of Email::HookCreator::Base class
      #
      def initialize(params)
        @email = params[:email]
        @custom_description = params[:custom_description]
        @custom_attributes = params[:custom_attributes] || {}
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform

        r = validate
        return r unless r.success?

        handle_event

      end

      private

      # Validate
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate
        fail 'sub class to implement'
      end

      # Event type
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [String] event type that goes into hook table
      #
      def event_type
        fail 'sub class to implement'
      end

      # sub classes to implement logic of handling an event here
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def handle_event
        fail 'sub class to implement'
      end

      # Validate email
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate_email

        if Util::CommonValidator.is_valid_email?(@email) && Util::CommonValidator.is_email_send_allowed?(@email)
          success
        else
          error_with_data(
            'e_hc_stm_3',
            'Invalid Email',
            'Invalid Email',
            GlobalConstant::ErrorAction.default,
            {}
          )
        end

      end

      # Validate Custom Attributes
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate_custom_variables

        return success if @custom_attributes.blank?

        unsupported_keys = @custom_attributes.keys - GlobalConstant::PepoCampaigns.allowed_custom_attributes

        unsupported_keys.blank? ? success :
            error_with_data(
                'e_hc_uc_2',
                'unsupported attributes',
                "unsupported attributes: #{unsupported_keys}",
                GlobalConstant::ErrorAction.default,
                {}
            )

      end

      # Create new hook
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @param [String] event_type
      # @param [Hash] params
      #
      def create_hook(params = {})
        EmailServiceApiCallHook.create!(
          event_type: event_type,
          email: @email,
          execution_timestamp: params[:execution_timestamp] || current_timestamp,
          custom_description: @custom_description,
          params: params
        )
      end

    end

  end

end