module Email

  module HookProcessor

    class UpdateContact < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @param [EmailServiceApiCallHook] hook (mandatory) - db record of EmailServiceApiCallHook table
      #
      # @return [Email::HookProcessor::UpdateContact] returns an object of Email::HookProcessor::UpdateContact class
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

      # validate
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate

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
        if false # TODO: Implememnt logic
          GlobalConstant::PepoCampaigns.verified_value
        else
          GlobalConstant::PepoCampaigns.pending_value
        end
      end

      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [String]
      #
      def blacklist_status_setting_value
        if true # TODO: Implememnt logic
          GlobalConstant::PepoCampaigns.blacklisted_value
        else
          GlobalConstant::PepoCampaigns.unblacklisted_value
        end
      end

      # process hook
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook

        update_contact_response = Email::Services::PepoCampaigns.new.update_contact(
          *add_update_contact_params
        )

        if update_contact_response['error'].present?
          error_with_data(
            'e_hp_uc_1',
            'API Call to Email Service Failed',
            update_contact_response
          )
        else
          success_with_data(update_contact_response)
        end

      end

    end

  end

end
