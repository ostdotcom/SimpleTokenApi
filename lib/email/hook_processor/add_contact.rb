module Email

  module HookProcessor

    class AddContact < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @param [EmailServiceApiCallHook] hook (mandatory) - db record of EmailServiceApiCallHook table
      #
      # @return [Email::HookProcessor::AddContact] returns an object of Email::HookProcessor::AddContact class
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform
        super
      end

      private

      # validate
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate

        success

      end

      # Start processing hook
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook

        add_contact_response = Email::Services::PepoCampaigns.new.add_contact(
          *add_update_contact_params
        )

        if add_contact_response['error'].present?
          error_with_data(
            'e_hp_ac_1',
            'API Call to Email Service Failed',
            'API Call to Email Service Failed',
            GlobalConstant::ErrorAction.default,
            add_contact_response
          )
        else
          if @hook.params[:dont_send_double_opt_in_email]
            success_with_data(add_contact_response)
          else
            r = create_hook_to_send_double_otp_in_mail
            if r.success?
              success_with_data(add_contact_response)
            else
              error_with_data(
                'e_hp_ac_2',
                "Couldn't create hook to send transactional email",
                "Couldn't create hook to send transactional email",
                GlobalConstant::ErrorAction.default,
                r.to_json
              )
            end
          end
        end

      end

      # Create transactional email template
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      def create_hook_to_send_double_otp_in_mail

        EmailServiceApiCallHook.create(
          email: @hook.email,
          event_type: GlobalConstant::EmailServiceApiCallHook.send_double_opt_in_mail_event_type,
          custom_description: @hook.custom_description,
          execution_timestamp: Time.now.to_i,
          params: {
            template_name: @hook.params[:template_name],
            template_vars: {}
          }
        )

        success

      end

      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [String]
      #
      def double_opt_in_status_setting_value
        GlobalConstant::PepoCampaigns.verified_value
      end

      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [String]
      #
      def blacklist_status_setting_value
        GlobalConstant::PepoCampaigns.unblacklisted_value
      end

    end

  end

end
