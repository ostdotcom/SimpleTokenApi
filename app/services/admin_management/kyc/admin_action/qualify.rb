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
        # @params [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::Qualify]
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

          update_user_kyc_status

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

          return success unless is_duplicate_kyc_approved_user?

          error_with_data(
              'am_k_aa_qf_1',
              'Duplicate Kyc User for approval.',
              'Duplicate Kyc User for approval.',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        # Check if Duplicate KYC Approved User
        #
        # * Author: Abhay
        # * Date: 30/10/2017
        # * Reviewed By: Sunil
        #
        # return [Bool] true/false
        #
        def is_duplicate_kyc_approved_user?
          u_e_d = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first

          hashed_ethereurm_address = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.ethereum_address)
          hashed_nationality = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.nationality)
          hashed_passport_number = Util::Encryption::Admin.get_sha256_hashed_value_from_kms_encrypted_value(u_e_d.kyc_salt, u_e_d.passport_number)

          user_extended_detail_ids = Md5UserExtendedDetail.
              where('(ethereum_address = ?) or (passport_number = ? && nationality = ?)', hashed_ethereurm_address, hashed_passport_number, hashed_nationality).
              pluck(:user_extended_detail_id)

          user_extended_detail_ids.delete(@user_kyc_detail.user_extended_detail_id)
          return false if user_extended_detail_ids.blank?
          UserKycDetail.where(user_extended_detail_id: user_extended_detail_ids, admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses).exists?
        end

        # Change case's admin status
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def update_user_kyc_status
          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
          @user_kyc_detail.last_acted_by = @admin_id
          # NOTE: we don't want to change the updated_at at this action. Don't touch before asking Sunil
          @user_kyc_detail.save!(touch: false) if @user_kyc_detail.changed?
        end

      end

    end

  end

end
