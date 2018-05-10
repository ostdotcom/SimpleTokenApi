module AdminManagement

  module Kyc

    class UpdateEthereumAddress < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] case_id (mandatory) - search term to find case
      # @params [String] ethereum_address (mandatory) - Ethereum address to be changed.
      #
      # @return [AdminManagement::Kyc::UpdateEthereumAddress]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]
        @new_ethereum_address = @params[:ethereum_address]

        @user_kyc_detail = nil
        @user_extended_details = nil
        @old_ethereum_address = nil
        @old_md5_ethereum_address = nil
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        encrypt_ethereum_address
        return r unless r.success?

        create_edit_kyc_request

        r = update_tables
        return r unless r.success?

        handle_duplicate_logs

        success_with_data({})

      end

      private

      # Validate all the Input parameters before posting Edit Kyc Requests
      #
      # * Author: Pankaj
      # * Date: 04/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = validate_ethereum_address
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        return error_with_data(
            'am_k_uea_1',
            'Admin does not have rights to perform this action.',
            'Admin does not have rights to perform this action.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @admin.default_client_id != @client.id

        # Check for pending edit kyc requests
        edit_kyc_request = EditKycRequests.under_process.where(case_id: @case_id).first

        return error_with_data(
            'am_k_uea_2',
            'Edit request is in process for this case.',
            'Edit request is in process for this case.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if edit_kyc_request.present?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_uea_3',
            'Kyc Details not found or its closed.',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank? || @user_kyc_detail.case_closed_for_admin?

        @user_extended_details = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first

        success
      end

      # validate ethereum address
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_ethereum_address

        @new_ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@new_ethereum_address)

        # Regex check for Ethereum address
        return error_with_data(
            'am_k_uea_4',
            'Invalid Ethereum Address',
            'Invalid Ethereum Address',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless Util::CommonValidator.is_ethereum_address?(@new_ethereum_address)

        # check with the private geth for address validation
        r = UserManagement::CheckEthereumAddress.new(ethereum_address: @new_ethereum_address).perform
        return error_with_data(
            'am_k_uea_4',
            'Invalid Ethereum Address!',
            'Invalid Ethereum Address!',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless r.success?

        r = check_for_duplicate_ethereum
        return r unless r.success?

        success
      end

      # encrypt ethereum address.
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def encrypt_ethereum_address

        r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_details.kyc_salt)
        return r unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj ||= LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.encrypt(@new_ethereum_address)
        return r unless r.success?
        @encrypted_ethereum_address = r.data[:ciphertext_blob]

        success
      end

      # Create Edit KYC request for update Ethereum
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      # Sets @edit_kyc_request
      #
      def create_edit_kyc_request
        @edit_kyc_request = EditKycRequests.create!(
            case_id: @case_id,
            admin_id: @admin_id,
            user_id: @user_kyc_detail.user_id,
            update_action: GlobalConstant::EditKycRequest.update_ethereum_action,
            status: GlobalConstant::EditKycRequest.in_process_status,
            ethereum_address: @encrypted_ethereum_address
        )
      end

      # Update Ethereum address in table and mark process as complete
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      # Sets @old_ethereum_address
      #
      def update_tables
        @old_ethereum_address = @user_extended_details.ethereum_address

        @user_extended_details.ethereum_address = @encrypted_ethereum_address
        @user_extended_details.save!

        update_user_md5_extended_details

        @edit_kyc_request.status = GlobalConstant::EditKycRequest.processed_status
        @edit_kyc_request.save!

        log_activity

        success
      end

      # Update User hashed Ethereum Address in MD5 Extended Details
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      # Sets @old_md5_ethereum_address
      #
      def update_user_md5_extended_details

        md5_user_extended_detail = Md5UserExtendedDetail.where(user_extended_detail_id: @user_kyc_detail.user_extended_detail_id).first
        @old_md5_ethereum_address = md5_user_extended_detail.ethereum_address
        md5_user_extended_detail.ethereum_address = Md5UserExtendedDetail.get_hashed_value(@ethereum_address)
        md5_user_extended_detail.save!

        success
      end

      # Check whether Ethereum address is already present
      #
      # * Author: Pankaj
      # * Date: 08/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def check_for_duplicate_ethereum
        # Check for duplicate Ethereum address
        hashed_db_ethereurm_address = Md5UserExtendedDetail.get_hashed_value(@new_ethereum_address)
        user_extended_detail_ids = Md5UserExtendedDetail.where(ethereum_address: hashed_db_ethereurm_address).pluck(:user_extended_detail_id)

        # Ethereum address is already present
        if user_extended_detail_ids.present?
          # Check whether duplicate address kyc is already approved
          already_approved_cases = []
          UserKycDetail.where(client_id: @user_kyc_detail.client_id, user_extended_detail_id: user_extended_detail_ids).each do |ukd|
            if ukd.kyc_approved?
              already_approved_cases << ukd.id
            end
          end
          return error_with_data(
              'am_k_uea_5',
              "Duplicate Ethereum address cases has already been approved, Case Ids #{already_approved_cases}",
              "Duplicate Ethereum address cases has already been approved, Case Ids #{already_approved_cases}",
              GlobalConstant::ErrorAction.default,
              {}
          ) if already_approved_cases.present?
        end

        success

      end



      # Enqueue Log Activity
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def log_activity
        BgJob.enqueue(
            UserActivityLogJob,
            {
                user_id: @user_kyc_detail.user_id,
                admin_id: @admin.id,
                action: GlobalConstant::UserActivityLog.update_ethereum_address,
                action_timestamp: Time.now.to_i,
                extra_data: {
                    case_id: @case_id,
                    old_encrypted_u_e_d_ethereum_address: @old_ethereum_address,
                    old_md5_ethereum_address: @old_md5_ethereum_address
                }
            }
        )
      end

      #  Handle Duplicate Logs
      #
      # * Author: Abhay
      # * Date: 10/11/2017
      # * Reviewed By: Kedar
      #
      # @return [Result::Base]
      #
      def handle_duplicate_logs
        all_non_current_user_dup_user_extended_details_ids = []

        # Fetch all user_extended_details corresponding to current user_extended_details1_id
        all_non_current_user_dup_user_extended_details_ids += UserKycDuplicationLog.where(
            user_extended_details1_id: @user_kyc_detail.user_extended_detail_id, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user_extended_details2_id)

        # Fetch all user_extended_details corresponding to current user_extended_details2_id
        all_non_current_user_dup_user_extended_details_ids += UserKycDuplicationLog.where(
            user_extended_details2_id: @user_kyc_detail.user_extended_detail_id, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user_extended_details1_id)

        # Initiailize
        active_dup_user_extended_details_ids, inactive_dup_user_extended_details_ids, user_ids = [], [], []
        # Fetch active, inactive user_extended_details_ids
        UserKycDuplicationLog.where("user_extended_details1_id IN (?) OR user_extended_details2_id IN (?)", all_non_current_user_dup_user_extended_details_ids, all_non_current_user_dup_user_extended_details_ids).
            where(status: [GlobalConstant::UserKycDuplicationLog.active_status, GlobalConstant::UserKycDuplicationLog.inactive_status]).
            select(:id, :user1_id, :user2_id, :user_extended_details1_id, :user_extended_details2_id, :status).all.each do |ukdl|

          next if (ukdl.user_extended_details1_id == @user_kyc_detail.user_extended_detail_id) || (ukdl.user_extended_details2_id == @user_kyc_detail.user_extended_detail_id)

          if ukdl.status == GlobalConstant::UserKycDuplicationLog.active_status
            active_dup_user_extended_details_ids << ukdl.user_extended_details1_id
            active_dup_user_extended_details_ids << ukdl.user_extended_details2_id
          else
            inactive_dup_user_extended_details_ids << ukdl.user_extended_details1_id
            inactive_dup_user_extended_details_ids << ukdl.user_extended_details2_id
          end
          user_ids << ukdl.user1_id
          user_ids << ukdl.user2_id
        end if all_non_current_user_dup_user_extended_details_ids.present?

        active_dup_user_extended_details_ids.uniq!
        inactive_dup_user_extended_details_ids.uniq!
        user_ids.uniq!

        inactive_dup_user_extended_details_ids -= active_dup_user_extended_details_ids
        # Mark inactive user_extended_details_ids as was_kyc_duplicate_status
        # Active user_kyc_details will already be is_kyc_duplicate_status
        if inactive_dup_user_extended_details_ids.present?
          UserKycDetail.where(user_extended_detail_id: inactive_dup_user_extended_details_ids).
              update_all(kyc_duplicate_status: GlobalConstant::UserKycDetail.was_kyc_duplicate_status)
        end

        never_dup_user_extended_details_ids = (all_non_current_user_dup_user_extended_details_ids - active_dup_user_extended_details_ids - inactive_dup_user_extended_details_ids)
        # Mark missing dup_user_extended_details_ids as never_kyc_duplicate_status
        if never_dup_user_extended_details_ids.present?
          UserKycDetail.where(user_extended_detail_id: never_dup_user_extended_details_ids).
              update_all(kyc_duplicate_status: GlobalConstant::UserKycDetail.never_kyc_duplicate_status)
        end

        # Delete all entries corresponding to all_non_current_user_dup_user_extended_details_ids
        UserKycDuplicationLog.where("user_extended_details1_id = ? OR user_extended_details2_id = ?",
                                    @user_kyc_detail.user_extended_detail_id, @user_kyc_detail.user_extended_detail_id).delete_all

        # Mark current user as unprocessed
        @user_kyc_detail.kyc_duplicate_status = GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status
        @user_kyc_detail.save!
        # Perform Check duplicates again for current user id
        r = AdminManagement::Kyc::CheckDuplicates.new(user_id: @user_kyc_detail.user_id).perform
        return r unless r.success?

        UserKycDetail.bulk_flush(user_ids)

        success
      end

    end

  end

end
