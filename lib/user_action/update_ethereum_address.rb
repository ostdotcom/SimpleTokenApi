module UserAction

  class UpdateEthereumAddress

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @param [Integer] case_id (mandatory)
    # @param [String] ethereum_address (mandatory)
    # @param [String] admin_email (mandatory)
    # @param [String] user_email (mandatory)
    #
    # @return [UserManagement::UpdateEthereumAddress]
    #
    # Sets @case_id, @ethereum_address, @admin_email, @user_email
    #
    def initialize(params)

      @case_id = params[:case_id]
      @ethereum_address = params[:ethereum_address]
      @admin_email = params[:admin_email]
      @user_email = params[:user_email]

      @old_md5_ethereum_address, @old_encrypted_u_e_d_ethereum_address = nil, nil

    end

    # Perform
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = update_user_extended_details
      return r unless r.success?

      r = update_user_md5_extended_details
      return r unless r.success?

      r = handle_duplicate_logs
      return r unless r.success?

      r = log_activity
      return r unless r.success?

      r = verify_updated_ethereum_address
      return r unless r.success?

      success
    end

    private

    # Validate and Sanitize
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    # Sets @user_kyc_detail, @admin
    #
    def validate_and_sanitize

      @ethereum_address = @ethereum_address.to_s.strip
      @case_id = @case_id.to_i
      @admin_email = @admin_email.to_s.strip.downcase
      @user_email = @user_email.to_s.strip.downcase

      if @ethereum_address.blank? || @case_id < 1 || @admin_email.blank? || @user_email.blank?
        return error_with_data(
          'ua_uea_1',
          'Ethereum Address, Case ID, Admin Email, User Email is mandatory!',
          'Ethereum Address, Case ID, Admin Email, User Email is mandatory!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      # add 0x in the beginning if not present
      @ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@ethereum_address)

      # regex check
      if !Util::CommonValidator.is_ethereum_address?(@ethereum_address)
        return error_with_data(
          'ua_uea_2',
          'Invalid Ethereum Address format!',
          'Invalid Ethereum Address format!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      # check with the private geth for address validation
      r = UserManagement::CheckEthereumAddress.new(ethereum_address: @ethereum_address).perform
      if !r.success?
        return error_with_data(
          'ua_uea_3',
          'Invalid Ethereum Address!',
          'Invalid Ethereum Address!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @user_kyc_detail = UserKycDetail.where(id: @case_id).first

      if @user_kyc_detail.blank?
        return error_with_data(
          'ua_uea_4',
          "Invalid Case ID - #{@case_id}",
          "Invalid Case ID - #{@case_id}",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      if @user_kyc_detail.case_closed?
        return error_with_data(
          'ua_uea_5',
          "Case ID - #{@case_id} should be open.",
          "Case ID - #{@case_id} should be open.",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @admin = Admin.where(email: @admin_email, status: GlobalConstant::Admin.active_status).first
      if @admin.blank?
        return error_with_data(
          'ua_uea_6',
          "Invalid Active Admin Email - #{@admin_email}",
          "Invalid Active Admin Email - #{@admin_email}",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      r = is_duplicate_ethereum_address?
      unless r.success?
        user_ids = UserExtendedDetail.where(id: r.data[:user_extended_detail_ids]).pluck(:user_id)
        user_emails = User.where(id:user_ids).pluck(:email)
        user_kyc_detail_ids = UserKycDetail.where(user_id: user_ids).pluck(:id)
        return error_with_data(
          'ua_uea_7',
          "Duplicate ethereum Address Found with email: #{user_emails}, case ids: #{user_kyc_detail_ids}, user_ids: #{user_ids}, UserExtendedDetail ids: #{r.data[:user_extended_detail_ids]}",
          "Duplicate ethereum Address Found with email: #{user_emails}, case ids: #{user_kyc_detail_ids}, user_ids: #{user_ids}, UserExtendedDetail ids: #{r.data[:user_extended_detail_ids]}",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      if !User.where(id: @user_kyc_detail.user_id, email: @user_email,
                     status: GlobalConstant::User.active_status).exists?
        return error_with_data(
          'ua_uea_8',
          "User Email: #{@user_email} is Invalid or Not Active!",
          "User Email: #{@user_email} is Invalid or Not Active!",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      success
    end

    # Check if Duplicate Ethereum Address
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # return [Bool] true/false
    #
    def is_duplicate_ethereum_address?
      hashed_db_ethereurm_address = Md5UserExtendedDetail.get_hashed_value(@ethereum_address)
      user_extended_detail_ids = Md5UserExtendedDetail.where(ethereum_address: hashed_db_ethereurm_address).pluck(:user_extended_detail_id)

      if user_extended_detail_ids.present?
        return error_with_data(
          'ua_uea_9',
          "Duplicate ethereum Address found in MD5 table",
          "Duplicate ethereum Address found in in MD5 table",
          GlobalConstant::ErrorAction.default,
          {user_extended_detail_ids: user_extended_detail_ids}
        )
      end
      success
    end

    # Update User encrypted Ethereum address in Extended Details
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    # Sets @kyc_salt_d, @old_encrypted_u_e_d_ethereum_address
    #
    def update_user_extended_details

      user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first

      @old_encrypted_u_e_d_ethereum_address = user_extended_detail.ethereum_address

      r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)
      return r unless r.success?

      @kyc_salt_d = r.data[:plaintext]
      r = encryptor_obj.encrypt(@ethereum_address)
      return r unless r.success?

      user_extended_detail.ethereum_address = r.data[:ciphertext_blob]
      user_extended_detail.save!

      success
    end

    # Update User hashed Ethereum Address in MD5 Extended Details
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
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

    # Get Encryptor Object
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @return [LocalCipher]
    #
    # Sets @local_cipher_obj
    #
    def encryptor_obj
      @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
    end

    # Handle Duplicate Logs
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

    # Log to UserActivityLog Table
    #
    # * Author: Abhay
    # * Date: 10/11/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
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
            old_encrypted_u_e_d_ethereum_address: @old_encrypted_u_e_d_ethereum_address,
            old_md5_ethereum_address: @old_md5_ethereum_address
          }
        }
      )

      success
    end

    # Verify updated ethereum address
    #
    # * Author: Abhay
    # * Date: 13/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def verify_updated_ethereum_address

      user_kyc_detail = UserKycDetail.where(id: @case_id).first
      @user_extended_detail = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first

      r = encryptor_obj.decrypt(@user_extended_detail.ethereum_address)
      return r unless r.success?

      decrypted_ethereum_address = r.data[:plaintext]
      p "Decrypted ethereum address: #{decrypted_ethereum_address}"

      if decrypted_ethereum_address != @ethereum_address
        return error_with_data(
          'ua_uea_9',
          "Decrypted Ethereum Address is not matching with updated ethereum address",
          "Decrypted Ethereum Address is not matching with updated ethereum address",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      p "######  NEW ETHEREUM ADDRESS: #{decrypted_ethereum_address}  ######"
      p "updated ethereum address is matching successfully"

      success
    end

  end

end