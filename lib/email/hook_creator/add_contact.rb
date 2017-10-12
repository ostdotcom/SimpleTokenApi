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
      # @param [String] double_opt_in_template_name (mandatory) - template of the email that has to be sent out for Double Opt in
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::AddContact] returns an object of Email::HookCreator::AddContact class
      #
      def initialize(params)
        super
        @template_name = params[:double_opt_in_template_name]
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

        return pending_hook_exists_response if pending_hook_to_be_processed_later?

        create_hook(
          double_opt_in_token: '',
          template_name: @template_name
        )

        success

      end

      # find if existing hook exists in DB which would be processed later
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Boolean] - true if pending hook exists
      #
      def pending_hook_to_be_processed_later?

        #TODO: Do we need this ?

        false

      end

    end

  end

end
