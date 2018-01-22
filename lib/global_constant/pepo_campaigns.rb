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

      def version
        config[:api][:version]
      end

      def api_timeout
        5
      end

      ########### List Ids ############

      def master_list_id
        config[:list_ids][:master_list]
      end

      ########### User Custom Attributes #########

      def token_sale_phase_attribute
        'token_sale_phase'
      end

      def token_sale_registered_attribute
        'token_sale_registered'
      end

      def token_sale_kyc_confirmed_attribute
        'token_sale_kyc_confirmed'
      end

      def token_sale_has_purchased_attribute
        'token_sale_has_purchased'
      end

      def allowed_custom_attributes
        [
          token_sale_registered_attribute,
          token_sale_phase_attribute,
          token_sale_kyc_confirmed_attribute,
          token_sale_has_purchased_attribute
        ]
      end

      ########### User Setting : Keys ############

      def double_opt_in_status_user_setting
        'double_opt_in_status'
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

      ################ Custom Attribute Values ################

      def token_sale_registered_value
        1
      end

      def token_sale_kyc_confirmed_value
        1
      end

      def token_sale_has_purchased_value
        1
      end

      ############# Custom Attribute Values ################

      # double optin email - sent when user is adding email for the first time
      def double_opt_in_template
        'token_sale_double_opt'
      end

      # reset password email - sent when user clicks on forgot password
      def forgot_password_template
        'forgot_password'
      end

      # kyc_data_mismatch email - sent when user clicks on data_mismatch on admin panel
      def kyc_data_mismatch_template
        'kyc_data_mismatch'
      end

      # passport_issue email - sent when user clicks on "passport issue" on admin panel
      def kyc_passport_issue_template
        'kyc_document_issue'
      end

      # selfie_image_issue email - sent when user clicks on "selfie image issue" on admin panel
      def kyc_selfie_image_issue_template
        'kyc_selfie_image_issue'
      end

      # kyc_residence_image_issue email - sent when user clicks on "residence image issue" on admin panel
      def kyc_residency_image_issue_template
        'kyc_residency_image_issue'
      end

      # kyc_approved email - sent when kyc is approved by cynopsis and admin both.
      def kyc_approved_template
        'kyc_approved'
      end

      def purchase_confirmation
        'purchase_confirmation'
      end

      def altdrop_sent
        'altdrop_sent'
      end

      # kyc_denied email - sent when kyc is denied by cynopsis and admin both.
      def kyc_denied_template
        'kyc_denied'
      end

      # contact us admin email for freshdesk
      def contact_us_template
        'contact_us'
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
          forgot_password_template,
          kyc_data_mismatch_template,
          kyc_passport_issue_template,
          kyc_selfie_image_issue_template,
          kyc_residency_image_issue_template,
          kyc_approved_template,
          kyc_denied_template,
          purchase_confirmation,
          altdrop_sent,
          contact_us_template
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
