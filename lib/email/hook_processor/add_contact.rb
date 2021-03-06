module Email

  module HookProcessor

    class AddContact < Base

      # Initialize
      #
      # * Author: Puneet
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
      # * Author: Puneet
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
      # * Author: Puneet
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
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook

        add_contact_response = pepo_campaign_obj.add_contact(
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
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def attributes_hash
        #TODO: Added temp check to smooth transition of old hooks
        if @hook.params[:token_sale_phase].present?
          {
            GlobalConstant::PepoCampaigns.token_sale_phase_attribute => @hook.params[:token_sale_phase]
          }
        else
          @hook.params[:custom_attributes] || {}
        end
      end

      # Build user settings for email service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def user_settings_hash
        # This was agreed with PMs
        if @hook.params[:list_id] != GlobalConstant::PepoCampaigns.master_list_id
          {
              GlobalConstant::PepoCampaigns.subscribe_status_user_setting => GlobalConstant::PepoCampaigns.subscribed_value
          }
        else
          {
              GlobalConstant::PepoCampaigns.double_opt_in_status_user_setting => double_opt_in_status_setting_value,
              GlobalConstant::PepoCampaigns.subscribe_status_user_setting => GlobalConstant::PepoCampaigns.subscribed_value
          }
        end
      end

      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Suil
      #
      # @return [String]
      #
      def double_opt_in_status_setting_value
        GlobalConstant::PepoCampaigns.verified_value
      end

    end

  end

end
