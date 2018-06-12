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
      # @params [Integer] client_id (mandatory) - client id
      # @params [Hash] custom_attributes (optional) - attribute which are to be set for this email
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::AddContact] returns an object of Email::HookCreator::AddContact class
      #
      def initialize(params)
        super
        @list_id = params[:list_id]
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
          'e_hc_ac_1',
          'mandatory param email missing',
          'mandatory param email missing',
          GlobalConstant::ErrorAction.default,
          {}
        ) if @email.blank?

        r = validate_for_email_setup
        return r unless r.success?

        r = validate_list_id
        return r unless r.success?

        return error_with_data(
            'e_hc_ac_2',
            'Add contact cannot be done for clients',
            'Add contact cannot be done for clients',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client_id.blank? || GlobalConstant::TokenSale.st_token_sale_client_id == @client_id

        validate_custom_variables

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
          custom_attributes: @custom_attributes,
          list_id: @list_id
        )

        success

      end

    end

  end

end
