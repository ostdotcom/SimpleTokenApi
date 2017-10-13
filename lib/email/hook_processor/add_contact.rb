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
          success_with_data(add_contact_response)
        end

      end

      # Build attributes for email service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def attributes_hash
        {
          GlobalConstant::PepoCampaigns.token_sale_phase_attribute => @hook.params[:token_sale_phase]
        }
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
