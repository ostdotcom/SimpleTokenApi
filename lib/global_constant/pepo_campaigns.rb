# frozen_string_literal: true
module GlobalConstant

  class PepoCampaigns

    class << self

      ########### Config ############

      def api_key
        config[:api][:key]
      end

      def api_secret
        config[:api][:secret]
      end

      def base_url
        config[:api][:base_url]
      end

      ########### List Ids ############

      def master_list_id
        config[:list_ids][:master_list]
      end

      ########### User Setting : Keys ############

      def double_opt_in_status_user_setting
        'double_opt_in_status'
      end

      def blacklist_status_user_setting
        'blacklist_status'
      end

      def subscribe_status_user_setting
        'subscribe_status'
      end

      def hardbounce_status_user_setting
        'hardbounce_status'
      end

      def complaint_status_user_setting
        'complaint_status'
      end

      ########### User Setting : Possible Values ############

      def blacklisted_value
        'blacklisted'
      end

      def unblacklisted_value
        'unblacklisted'
      end

      def verified_value
        'verified'
      end

      def pending_value
        'pending'
      end

      def subscribed_value
        'subscribed'
      end

      def unsubscribed_value
        'unsubscribed'
      end

      ########### Transaction Email Templates ############

      # double optin email - sent when user is adding email for the first time
      def double_opt_in_template
        'token_sale_double_opt'
      end

      # double optin confirmation - sent when user status changes from pending to confirmed
      def welcome_mail_template
        'welcome_mail'
      end

      # All possible templates integrated with email service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Array]
      #
      def supported_templates
        [
          double_opt_in_template,
          welcome_mail_template
        ]
      end

      # is this template related to double opt in email
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def is_double_opt_in_related_template?(template_name)
        [
          GlobalConstant::PepoCampaigns.double_opt_in_template
        ].include?(template_name)
      end

      private

      def config
        GlobalConstant::Base.pepo_campaigns_config
      end

    end

  end

end



# 1. Registeration Not Complete (Verify Account - Double Opt in) - Prority
# 2. Verify Your KYC -  Prority
# 3. KYC Check Failed - KYC Denied - When Synopsis rejects or Admin rejects ??
# 4. Manually Triggered if documnets are mistach admin triggered
# 5. Kyc pre phase 1 - KYC Approved if Admin Panel & Synopsis both say Ok (Till 10th)
# 6. Kyc pre phase 2 - 11th to 14th
# 7. Kyc pre phase 3 - Starting 15th
# 8. Token Allocation Success
# 9. Pre Registeration Not Completed - 24 hours left - To users who gave emails but did not complete KYC. - Prority



