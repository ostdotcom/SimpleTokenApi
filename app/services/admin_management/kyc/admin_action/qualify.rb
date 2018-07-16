module AdminManagement

  module Kyc

    module AdminAction

      class Qualify < AdminManagement::Kyc::AdminAction::Base

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] id (mandatory)
        #
        # @params [Integer] is_auto_approve (Optional) - if its an auto approve qualify
        #
        # @return [AdminManagement::Kyc::AdminAction::Qualify]
        #
        def initialize(params)
          super
          @is_auto_approve = params[:is_auto_approve]
        end

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def perform

          r = validate_and_sanitize
          return r unless r.success?

          update_user_kyc_status

          send_approved_email

          #Dont log admin action on approved by admin

          success_with_data(@api_response_data)
        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def validate_and_sanitize
          r = super
          return r unless r.success?

          r = validate_if_case_closed_for_auto_approve_admin_action?
          return r unless r.success?

          if UserExtendedDetail.is_duplicate_kyc_approved_user?(@user_kyc_detail.client_id,
                                                                @user_kyc_detail.user_extended_detail_id)
            return error_with_data(
                GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc,
                'Duplicate Kyc User for approval.',
                'Duplicate Kyc User for approval.',
                GlobalConstant::ErrorAction.default,
                {}
            )
          end

          success
        end

        # If this request is by auto approve process to qualify the admin
        #
        # * Author: Aman
        # * Date: 10/07/2018
        # * Reviewed By:
        #
        # @return [Boolean] return true if auto approve qualify action
        #
        def is_auto_approve_admin?
          @is_auto_approve && @admin_id == Admin::AUTO_APPROVE_ADMIN_ID
        end

        # fetch admin and validate. -1 Admin Id is for auto approve. dummy admin obj is initialized
        #
        # * Author: Aman
        # * Date: 10/07/2018
        # * Reviewed By:
        #
        # Sets @admin
        #
        # @return [Result::Base]
        #
        def fetch_and_validate_admin
          if is_auto_approve_admin?
            @admin = Admin.new(id: @admin_id)
            success
          else
            super
          end
        end

        # check if auto approve action can be performed on this case
        #
        # * Author: Aman
        # * Date: 10/08/2018
        # * Reviewed By:
        #
        # @return [Boolean]
        #
        def validate_if_case_closed_for_auto_approve_admin_action?
          return success if !is_auto_approve_admin?

          return error_with_data(
              'am_k_aa_q_iccfa_1',
              'Case has already been auto approved',
              'Case has already been auto approved',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.has_been_auto_approved?

          return error_with_data(
              'am_k_aa_q_iccfa_2',
              'Case cannot be auto approved',
              'Case cannot be auto approved',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.last_reopened_at.to_i > 0

          return success
        end

        # Change case's admin status
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        #
        def update_user_kyc_status
          if is_auto_approve_admin?
            @user_kyc_detail.send("set_" + GlobalConstant::UserKycDetail.auto_approved_qualify_type)
          else
            @user_kyc_detail.send("set_" + GlobalConstant::UserKycDetail.manually_approved_qualify_type)
          end

          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.last_acted_timestamp = Time.now.to_i
          @user_kyc_detail.admin_action_types = 0

          # NOTE: we don't want to change the updated_at at this action. Don't touch before asking Sunil
          @user_kyc_detail.save!(touch: false) if @user_kyc_detail.changed?
        end

        # Send email
        #
        # * Author: Aman
        # * Date: 11/01/2018
        # * Reviewed By:
        #
        def send_approved_email
          return if !@client.is_email_setup_done? || @client.is_whitelist_setup_done? || @client.is_st_token_sale_client?

          @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

          if @user_kyc_detail.kyc_approved?
            Email::HookCreator::SendTransactionalMail.new(
                client_id: @client.id,
                email: @user.email,
                template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
                template_vars: {
                    token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
                    is_sale_active: @client_token_sale_details.has_token_sale_started?
                }
            ).perform
          end

        end

      end

    end

  end

end
