module Email

  module HookCreator

    class SendTransactionalMail < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @param [String] email (mandatory) - Email
      # @params [Integer] client_id (mandatory) - client id
      # @param [String] event_type (mandatory) - event_type that would go into hooks table
      # @param [String] template_name (mandatory) - Template Name
      # @param [Hash] template_vars (mandatory) - Template Vars
      # @params [String] custom_description (optional) - description which would be logged in email service hooks table
      #
      # @return [Email::HookCreator::SendTransactionalMail]  returns an object of Email::HookCreator::SendTransactionalMail class
      #
      def initialize(params)
        super
        @template_name = params[:template_name]
        @template_vars = params[:template_vars]
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

        r = validate_for_email_setup
        return r unless r.success?

        r = validate_template_name
        return r unless r.success?

        validate_template_vars

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
        GlobalConstant::EmailServiceApiCallHook.send_transactional_mail_event_type
      end

      # check if this template is supported currently
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate_template_name
        GlobalConstant::PepoCampaigns.supported_templates.include?(@template_name) ? success : error_with_data(
          'e_hc_stm_3',
          "un supported template: #{@template_name}",
          "un supported template: #{@template_name}",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      # depending on template name validate mandatory template vars
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate_template_vars

        if GlobalConstant::PepoCampaigns.is_double_opt_in_related_template?(@template_name)

          return error_with_data(
            'e_hc_stm_4',
            'mandatory template var double_opt_in_token missing',
            'mandatory template var double_opt_in_token missing',
            GlobalConstant::ErrorAction.default,
            {}
          ) if @template_vars[:double_opt_in_token].blank?

        elsif (GlobalConstant::PepoCampaigns.forgot_password_template == @template_name)

          return error_with_data(
              'e_hc_stm_5',
              'mandatory template var reset_password_token missing',
              'mandatory template var reset_password_token missing',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @template_vars[:reset_password_token].blank?

        end

        success

      end

      # create a hook to send transactional email
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def handle_event

        create_hook(
          {
            template_name: @template_name,
            template_vars: @template_vars
          }
        )

        success

      end

    end

  end

end
