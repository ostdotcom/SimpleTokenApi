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
      # @params [String] token_sale_phase (mandatory) - token_sale_phase property for this contact
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::AddContact] returns an object of Email::HookCreator::AddContact class
      #
      def initialize(params)
        super
        @token_sale_phase = params[:token_sale_phase]
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


        return error_with_data(
          'e_hc_uc_2',
          'mandatory param token_sale_phase missing',
          'mandatory param token_sale_phase missing',
          GlobalConstant::ErrorAction.default,
          {}
        ) if @token_sale_phase.blank?

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

        create_hook(
          token_sale_phase: @token_sale_phase
        )

        success

      end

    end

  end

end
