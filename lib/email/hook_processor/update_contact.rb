module Email

  module HookProcessor

    class UpdateContact < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
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
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform
        super
      end

      private

      # validate
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate

        success

      end

      # Start processing hook
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook

        update_contact_response = pepo_campaign_obj.update_contact(
          *add_update_contact_params
        )

        if update_contact_response['error'].present?
          error_with_data(
            'e_hp_ac_1',
            'API Call to Email Service Failed',
            'API Call to Email Service Failed',
            GlobalConstant::ErrorAction.default,
            update_contact_response
          )
        else
          success_with_data(update_contact_response)
        end

      end

      # Build attributes for email service
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def attributes_hash
        @hook.params[:custom_attributes] || {}
      end

      # Build user settings for email service
      #
      # * Author: Aman
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def user_settings_hash
        # WE DO NOT TOUCH SETTINGS IN UPDATE CONTACT AS OF NOW
        {}
      end

    end

  end

end
