module AdminManagement

  module Kyc

    module AdminAction

      class DataMismatch < AdminManagement::Kyc::AdminAction::Base

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] case_id (mandatory)
        # @params [String] email_temp_vars[:first_name] (optional)
        # @params [String] email_temp_vars[:last_name] (optional)
        # @params [String] email_temp_vars[:birthdate] (optional)
        # @params [String] email_temp_vars[:passport_number] (optional)
        # @params [String] email_temp_vars[:nationality] (optional)
        #
        # @return [AdminManagement::Kyc::AdminAction::DataMismatch]
        #
        def initialize(params)

          super

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

          log_admin_action

          send_email

          update_kyc_details

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

          return error_with_data(
              'am_k_aa_dm_1',
              'Please mention the reason of data mismatch.',
              'Please mention the reason of data mismatch.',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @email_temp_vars.blank?

          @extra_data = {
              error_fields: @email_temp_vars.map{|e_f_k, _| e_f_k.to_s.humanize}
          }

          success

        end

        # Send email
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def send_email

          Email::HookCreator::SendTransactionalMail.new(
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_data_mismatch_template,
              template_vars: @email_temp_vars
          ).perform

        end

        # Update Kyc Details
        #
        # * Author: Aman
        # * Date: 25/10/2017
        # * Reviewed By:
        #
        def update_kyc_details
          @user_kyc_detail.admin_action_type = GlobalConstant::UserKycDetail.data_mismatch_admin_action_type
          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.save! if @user_kyc_detail.changed?
        end

        # user action log table action name
        #
        # * Author: Aman
        # * Date: 21/10/2017
        # * Reviewed By: Sunil
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.data_mismatch_email_sent_action
        end

      end

    end

  end

end
