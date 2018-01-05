module AdminManagement

  module Kyc

    class ChangeAddressAndOpenCase < ServicesBase

      # Initialize
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] case_id (mandatory) - search term to find case
      # @params [String] ethereum_address (optional) - Ethereum address to be changed.
      #
      # @return [AdminManagement::Kyc::ChangeAddressAndOpenCase]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:case_id]
        @new_ethereum_address = @params[:ethereum_address]

        @user_kyc_detail = nil
        @api_response = {}
        @encrypted_ethereum_address = nil
      end

      # Perform
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        encrypt_ethereum_address
        return r unless r.success?

        EditKycRequests.create!(
            case_id: @case_id,
            admin_id: @admin_id,
            user_id:  @user_kyc_detail.user_id,
            ethereum_address: @encrypted_ethereum_address,
            open_case_only: @encrypted_ethereum_address.blank? ? 1 : 0
        )

        api_response

      end

      private

      # Format and send response.
      #
      # * Author: Alpesh, kushal
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        edit_kyc_request = EditKycRequests.where(case_id: @case_id, status: GlobalConstant::UserKycDetail.unprocessed_edit_kyc).first
        return error_with_data(
            'am_k_c_caaoc_3',
            'Edit request is in process for this case.',
            'Edit request is in process for this case.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if edit_kyc_request.present?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_c_caaoc_4',
            'KYC detail id not found',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank?

        @user_extended_details = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first

        success
      end

      # encrypt ethereum address.
      #
      # * Author: Alpesh, kushal
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def encrypt_ethereum_address
        return success if @new_ethereum_address.blank?

        r = Aws::Kms.new('kyc', 'admin').decrypt(@user_extended_details.kyc_salt)
        return r unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj ||= LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.encrypt(@new_ethereum_address)
        return r unless r.success?
        @encrypted_ethereum_address = r.data[:ciphertext_blob]

        success
      end

      # Format and send response.
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def api_response

        success_with_data(@api_response)
      end

    end

  end

end
