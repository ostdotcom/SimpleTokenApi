module Email

  module HookCreator

    # This would be called when the email has not been verified by a user
    #
    class AddContact < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @params [Hash] custom_attributes (optional) - attribute which are to be set for this email
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::AddContact] returns an object of Email::HookCreator::AddContact class
      #
      def initialize(params)
        super
        @custom_attributes = params[:custom_attributes] || {}
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform
        super
      end

      private

      # Validate
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate

        return error_with_data(
          'e_hc_uc_1',
          'mandatory param email missing',
          'mandatory param email missing',
          GlobalConstant::ErrorAction.default,
          {}
        ) if @email.blank?

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

      # Event type
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String] event type that goes into hook table
      #
      def event_type
        GlobalConstant::EmailServiceApiCallHook.add_contact_event_type
      end

      # create a hook to add contact
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def handle_event

        create_hook(
          custom_attributes: @custom_attributes
        )

        success

      end

    end

  end

end
