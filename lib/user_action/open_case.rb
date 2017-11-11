module UserAction

  class OpenCase

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @param [Integer] case_id (mandatory)
    # @param [String] admin_email (mandatory)
    #
    # @return [UserManagement::OpenCase]
    #
    # Sets @case_id, @admin_email, @user_email
    #
    def initialize(params)

      @case_id = params[:case_id]
      @admin_email = params[:admin_email]
      @user_email = params[:user_email]

    end

    # Perform
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = make_whitelist_api_call_for_phase_zero
      return r unless r.success?

      r = open_case
      return r unless r.success?

      r = log_activity
      return r unless r.success?

      success
    end

    # Validate and Sanitize
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @user_kyc_detail, @admin, @user_extended_detail
    #
    def validate_and_sanitize

      @case_id = @case_id.to_i
      @admin_email = @admin_email.to_s.strip
      @user_email = @user_email.to_s.strip

      if @case_id < 1 || @admin_email.blank? || @user_email.blank?
        return error_with_data(
          'ua_oc_1',
          'Case ID, Admin Email, User Email is mandatory!',
          'Case ID, Admin Email, User Email is mandatory!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @admin = Admin.where(email: @admin_email, status: GlobalConstant::Admin.active_status).first
      if @admin.blank?
        return error_with_data(
          'ua_uea_2',
          "Invalid Active Admin Email - #{@admin_email}",
          "Invalid Active Admin Email - #{@admin_email}",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @user_kyc_detail = UserKycDetail.where(id: @case_id).first
      if @user_kyc_detail.blank?
        return error_with_data(
          'ua_oc_3',
          'Invalid Case ID!',
          'Invalid Case ID!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      if !User.where(id: @user_kyc_detail.user_id, email: @user_email,
                     status: GlobalConstant::User.active_status).exists?
        return error_with_data(
          'ua_uea_4',
          "User Email: #{@user_email} is Invalid or Not Active!",
          "User Email: #{@user_email} is Invalid or Not Active!",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      if !@user_kyc_detail.case_closed?
        return error_with_data(
          'ua_uea_5',
          "Case ID - #{@case_id} should be closed.",
          "Case ID - #{@case_id} should be closed.",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
      if @user_extended_detail.blank?
        return error_with_data(
          'ua_uea_6',
          'Invalid User Extended Details!',
          'Invalid User Extended Details!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      r = decrypt_ethereum_address
      return r unless r.success?

      if PurchaseLog.of_ethereum_address(@ethereum_address).exists?
        return error_with_data(
          'ua_uea_7',
          "User already bought SimpleToken. His case can't be opened",
          "User already bought SimpleToken. His case can't be opened",
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      # TODO::Any kyc_whitelist_logs checks

      # TODO:: Time Checks

      success
    end

    # Decrypt Ethereum Address
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @kyc_salt_d, @ethereum_address
    #
    def decrypt_ethereum_address

      r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_detail.kyc_salt)

      unless r.success?
        return error_with_data(
          'ua_uea_5',
          'Error decrypting Kyc salt!',
          'Error decrypting Kyc salt!',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      @kyc_salt_d = r.data[:plaintext]

      r = local_cipher_obj.decrypt(@user_extended_detail.ethereum_address)
      return r unless r.success?

      @ethereum_address = r.data[:plaintext]
      p "eth address: #{@ethereum_address}"

      success
    end

    # Make Whitelist API call
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def make_whitelist_api_call_for_phase_zero
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - making private ops api call")

      r = OpsApi::Request::Whitelist.new.whitelist({address: api_data[:address], phase: api_data[:phase]})
      Rails.logger.info("Whitelist API Response: #{r.inspect}")

      r
    end

    # Open Case DB Changes
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    def open_case

      @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.un_processed_admin_status
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
      @user_kyc_detail.save!

      # TODO Handle kyc_whitelist_log - DELETE OLD ENTRY ?

      success
    end

    # API Data for phase 0
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def api_data
      {address: @ethereum_address, phase: 0}
    end

    # Construct local cipher object
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [LocalCipher]
    #
    # Sets @local_cipher_obj
    #
    def local_cipher_obj
      @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
    end

    # Log to UserActivityLog Table
    #
    # * Author: Abhay
    # * Date: 11/11/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def log_activity

      BgJob.enqueue(
        UserActivityLogJob,
        {
          user_id: @user_kyc_detail.user_id,
          admin_id: @admin.id,
          action: GlobalConstant::UserActivityLog.open_case,
          action_timestamp: Time.now.to_i,
          extra_data: {
            case_id: @case_id,
          }
        }
      )

      success
    end

  end

end