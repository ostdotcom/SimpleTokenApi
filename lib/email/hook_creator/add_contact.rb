module Email

  module HookCreator

    # This would be called when the email has not been verified by a user
    #
    class AddContact < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::AddContact] returns an object of Email::HookCreator::AddContact class
      #
      def initialize(params)
        super
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
        super
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

        return error_with_data(
          'e_hc_uc_1',
          'mandatory param email missing',
          'mandatory param email missing',
          GlobalConstant::ErrorAction.default,
          {}
        ) if @email.blank?

        r = validate_email
        return r unless r.success?

        success

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
        GlobalConstant::EmailServiceApiCallHook.add_contact_event_type
      end

      # create a hook to add contact
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def handle_event

        create_hook

        success

      end

    end

  end

end
