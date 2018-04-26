module AdminManagement

  module Kyc

    class RetryCynopsisUpload < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] case_id (mandatory) - search term to find case
      #
      # @return [AdminManagement::Kyc::RetryCynopsisUpload]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]

        @case_id = @params[:id]

        @user_kyc_detail, @user_extended_detail = nil, nil
        @cynopsis_status = GlobalConstant::UserKycDetail.unprocessed_cynopsis_status

        @kyc_salt_d = nil
      end

      # perform cynopsis add or update for kyc user
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        fetch_user_kyc

        r = validate_user_kyc
        return r unless r.success?

        fetch_user_extended_detail

        r = check_if_kyc_submit_job_has_run
        return r unless r.success?

        decrypt_kyc_salt

        r = call_cynopsis_api
        return r unless r.success?

        success
      end

      private

      # Fetch user kyc obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_detail
      #
      def fetch_user_kyc
        @user_kyc_detail = UserKycDetail.where(id: @case_id).first
      end

      # Validate if cynopsis upload should be retried for user kyc obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_user_kyc

        return error_with_data(
            'am_k_rcu_vuk_1',
            "Invalid Request For User kyc",
            "Invalid Request For User kyc",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.blank?

        return error_with_data(
            'am_k_rcu_vuk_2',
            "User kyc is already uploaded in cynopsis",
            "user kyc has been added to cynopsis",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.cynopsis_status != GlobalConstant::UserKycDetail.unprocessed_cynopsis_status

        success
      end

      # Fetch user extended detail obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @user_extended_detail
      #
      def fetch_user_extended_detail
        @user_extended_detail = UserExtendedDetail.where(user_id: @user_kyc_detail.user_id).last
      end

      # Validate if cynopsis upload is pending and not failed. If kyc_submit_job has not run the extended detail id is not updated
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def check_if_kyc_submit_job_has_run
        return error_with_data(
            'am_k_rcu_ciksjhr_1',
            "Kyc submit job pending",
            "Cynopsis update job is still pending.It must be updated soon",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.user_extended_detail_id != @user_extended_detail.id

        success
      end

      # Cynopsis add or update
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def call_cynopsis_api
        r = @user_kyc_detail.cynopsis_user_id.blank? ? create_cynopsis_case : update_cynopsis_case
        Rails.logger.info("-- retry for call_cynopsis_api r: #{r.inspect}")

        if !r.success?
          log_to_user_activity(r)
          return error_with_data(
              'am_k_rcu_cca_1',
              "There was some error in cynopsis update",
              "Unable to update in cynopsis. There was some error.",
              GlobalConstant::ErrorAction.default,
              {},
              {}
          )
        end

        response_hash = ((r.data || {})[:response] || {})
        @cynopsis_status = GlobalConstant::UserKycDetail.get_cynopsis_status(response_hash['approval_status'].to_s)
        save_cynopsis_status

        success
      end

      # Decrypt kyc salt
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # Sets @kyc_salt_d
      #
      def decrypt_kyc_salt
        Rails.logger.info('-- decrypt_kyc_salt')

        r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_detail.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        @kyc_salt_d = r.data[:plaintext]
      end

      # Create user in cynopsis
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def create_cynopsis_case
        Cynopsis::Customer.new(client_id: @user_kyc_detail.client_id).create(cynopsis_params)
      end

      # Update user in cynopsis
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def update_cynopsis_case
        Cynopsis::Customer.new(client_id: @user_kyc_detail.client_id).update(cynopsis_params, true)
      end

      # Log to user activity
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def log_to_user_activity(response)
        UserActivityLogJob.new().perform({
                                             user_id: @user_kyc_detail.user_id,
                                             action: GlobalConstant::UserActivityLog.cynopsis_api_error,
                                             action_timestamp: Time.now.to_i,
                                             extra_data: {
                                                 response: response.to_json
                                             }
                                         })
      end

      # local cipher obj
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def local_cipher_obj
        @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
      end

      # Create cynopsis params
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def cynopsis_params
        {
            rfrID: get_cynopsis_user_id,
            first_name: @user_extended_detail.first_name,
            last_name: @user_extended_detail.last_name,
            country_of_residence: local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext].upcase,
            date_of_birth: Date.parse(local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]).strftime("%d/%m/%Y"),
            identification_type: 'PASSPORT',
            identification_number: local_cipher_obj.decrypt(@user_extended_detail.document_id_number).data[:plaintext],
            nationality: local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext].upcase
        }
      end

      # Save cynopsis response status
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      def save_cynopsis_status
        Rails.logger.info('-- save_cynopsis_status')
        @user_kyc_detail.cynopsis_user_id = get_cynopsis_user_id
        @user_kyc_detail.cynopsis_status = @cynopsis_status
        @user_kyc_detail.save! if @user_kyc_detail.changed?
      end

      # Get cynopsis rfrID
      #
      # * Author: Aman
      # * Date: 25/04/2018
      # * Reviewed By:
      #
      # ts - (token sale)
      # Rails.env[0..1] - (de/sa/st/pr)
      #
      def get_cynopsis_user_id
        UserKycDetail.get_cynopsis_user_id(@user_kyc_detail.user_id)
      end

    end

  end

end
