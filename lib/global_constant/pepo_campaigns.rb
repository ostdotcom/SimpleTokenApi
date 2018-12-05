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
        10
      end

      ########### List Ids ############

      def master_list_id
        config[:list_ids][:master_list]
      end

      def kyc_product_list_id
        config[:list_ids][:kyc_product_list]
      end

      def alpha_4_list_id
        config[:list_ids][:alpha_4_users_list]
      end

      def allowed_list_ids
        [
            GlobalConstant::PepoCampaigns.kyc_product_list_id,
            GlobalConstant::PepoCampaigns.master_list_id,
            GlobalConstant::PepoCampaigns.alpha_4_list_id
        ]
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

      def kyc_marketing_attribute
        'kyc_marketing'
      end


      def first_name_attribute
        'First Name'
      end

      def last_name_attribute
        'Last Name'
      end

      ########### OST Email Attributes #########



      def company_name_attribute
        'company_name'
      end

      def project_description_attribute
        'project_description'
      end

      def kit_marketing_attribute
        'kit_marketing'
      end

      def name_poc_attribute
        'name_poc'
      end

      def team_bio_attribute
        'team_bio'
      end

      def video_url_attribute
        'video_url'
      end

      def url_blog_attribute
        'url_blog'
      end

      def project_url_attribute
        'project_url'
      end

      def tech_doc_attribute
        'tech_doc'
      end

      def twitter_handle_attribute
        'twitter_handle'
      end

      def organization_name_attribute
        'organization_name'
      end

      ########### OST Email Attributes End #########

      def allowed_custom_attributes
        [
          token_sale_registered_attribute,
          token_sale_phase_attribute,
          token_sale_kyc_confirmed_attribute,
          token_sale_has_purchased_attribute,
          kyc_marketing_attribute,
          first_name_attribute,
          last_name_attribute,
          company_name_attribute,
          project_description_attribute,
          kit_marketing_attribute,
          name_poc_attribute,
          team_bio_attribute,
          video_url_attribute,
          url_blog_attribute,
          project_url_attribute,
          tech_doc_attribute,
          twitter_handle_attribute,
          organization_name_attribute
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
      def user_forgot_password_template
        'forgot_password'
      end

      # reset password email - sent when Admin clicks on forgot password
      def admin_forgot_password_template
        'admin_forgot_password'
      end

      def admin_invite_template
        "admin_invite"
      end

      # # kyc_data_mismatch email - sent when user clicks on data_mismatch on admin panel
      # def kyc_data_mismatch_template
      #   'kyc_data_mismatch'
      # end
      #
      # # document_id_issue email - sent when user clicks on "document_id issue" on admin panel
      # def kyc_document_id_issue_template
      #   'kyc_document_issue'
      # end
      #
      # # selfie_image_issue email - sent when user clicks on "selfie image issue" on admin panel
      # def kyc_selfie_image_issue_template
      #   'kyc_selfie_image_issue'
      # end
      #
      # # kyc_residence_image_issue email - sent when user clicks on "residence image issue" on admin panel
      # def kyc_residency_image_issue_template
      #   'kyc_residency_image_issue'
      # end
      #

      def kyc_issue_template
        'kyc_issue'
      end

      # kyc_approved email - sent when kyc is approved by aml and admin both.
      def kyc_approved_template
        'kyc_approved'
      end

      def purchase_confirmation
        'purchase_confirmation'
      end

      def altdrop_sent
        'altdrop_sent'
      end

      # kyc_denied email - sent when kyc is denied by aml and admin both.
      def kyc_denied_template
        'kyc_denied'
      end

      # contact us admin email for freshdesk
      def contact_us_template
        'contact_us'
      end

      # email to kyc team if threshold for registrations reached
      def billing_plan_notification_template
        'billing_plan_notification'
      end

      # email to admins for low balance of whitelister
      def low_whitelister_balance_template
        'low_whitelister_balance'
      end

      # email to admin with csv download link
      def kyc_report_download_template
        'kyc_report_download'
      end

      # email to admins on edit kyc request for open cases
      def update_ethereum_request_outcome_template
        'update_ethereum_request_outcome'
      end

      # email to admins on edit kyc request for closed cases
      def open_case_request_outcome_template
        'open_case_request_outcome'
      end


      # auto respond email to user on contact us query for kyc
      def contact_us_ost_kyc_autoresponder_template
        'contact_us_ost_kyc_autoresponder'
      end

      # auto respond email to user on contact us query for partners
      def contact_us_ost_partner_autoresponder_template
        'contact_us_ost_partner_autoresponder'
      end

      # email to admins for whitelisting suspended due to low balance
      def low_balance_whitelisting_suspended_template
        'low_balance_whitelisting_suspended'
      end

      # email to admins for ethereum deposit or whitelist contract address update
      def contract_address_update_template
        'contract_address_update'
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
          admin_forgot_password_template,
          user_forgot_password_template,
          kyc_issue_template,
          admin_invite_template,

          # kyc_data_mismatch_template,
          # kyc_document_id_issue_template,
          # kyc_selfie_image_issue_template,
          # kyc_residency_image_issue_template,

          kyc_approved_template,
          kyc_denied_template,
          purchase_confirmation,
          altdrop_sent,
          contact_us_template,
          low_whitelister_balance_template,
          billing_plan_notification_template,
          update_ethereum_request_outcome_template,
          open_case_request_outcome_template,
          contact_us_ost_partner_autoresponder_template,
          contact_us_ost_kyc_autoresponder_template,
          kyc_report_download_template,
          low_balance_whitelisting_suspended_template,
          contract_address_update_template
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

      def kyc_approve_default_template_vars(client_id)
        client_token_sale_details = ::ClientTokenSaleDetail.get_from_memcache(client_id)
        {
            is_sale_active: client_token_sale_details.has_token_sale_started?
        }
      end


      def delete_hook_for_templates
        [GlobalConstant::PepoCampaigns.kyc_approved_template]
      end

      private

      def config
        GlobalConstant::Base.pepo_campaigns_config
      end

    end

  end

end
