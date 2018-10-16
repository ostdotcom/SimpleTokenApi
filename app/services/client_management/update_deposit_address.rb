module ClientManagement
  class UpdateDepositAddress < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [String] ethereum_deposit_address (optional) -  ethereum deposit address
    # @param [String] otp (mandatory) -  otp
    #
    # @return [ClientManagement::UpdateDepositAddress]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @ethereum_deposit_address = @params[:ethereum_deposit_address]
      @otp = @params[:otp].to_s

      @client_token_sale_details = nil
      @admin_secret_obj = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_and_validate_duplicate_ethereum_deposit_address
      return r unless r.success?

      r = fetch_admin_secret_obj
      return r unless r.success?

      r = validate_otp
      return r unless r.success?

      update_ethereum_deposit_address

      send_email

      success_with_data(success_response_data)
    end


    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_web_only_client
      return r unless r.success?

      r = validate_ethereum_deposit_address
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Web Only Client
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @client
    #
    def validate_web_only_client
      return error_with_identifier('forbidden_api_request', 'cm_uda_vwoc_1') unless @client.is_web_host_setup_done?
      success
    end

    # Validate Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_ethereum_deposit_address
      return success if @ethereum_deposit_address.blank?
      @ethereum_deposit_address = Util::CommonValidator.sanitize_ethereum_address(@ethereum_deposit_address)

      return error_with_identifier('invalid_api_params',
                                   'cm_uda_veda_1',
                                   ['invalid_ethereum_deposit_address'],
                                   'There were some errors in address submission. Please review and resubmit'
      ) if !(Util::CommonValidator.is_ethereum_address?(@ethereum_deposit_address))

      success
    end

    # Fetch And Validate Duplicate Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @client_token_sale_details
    #
    # @return [Result::Base]
    #
    def fetch_and_validate_duplicate_ethereum_deposit_address
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
      if @ethereum_deposit_address.blank?
        return error_with_identifier('invalid_api_params',
                                     'cm_uda_favdeda_1',
                                     ['duplicate_ethereum_deposit_address'],
                                     'There were some errors in address submission. Please review and resubmit'
        ) if @client_token_sale_details.ethereum_deposit_address.blank?
      else
        return error_with_identifier('invalid_api_params',
                                     'cm_uda_favdeda_2',
                                     ['duplicate_ethereum_deposit_address'],
                                     'There were some errors in address submission. Please review and resubmit'
        ) if get_decrypted_ethereum_deposit_address(@client_token_sale_details.ethereum_deposit_address).downcase == @ethereum_deposit_address.downcase
      end
      success
    end

    # fetch admin secret obj
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @admin_secret_obj
    #
    # @return [Result::Base]
    #
    def fetch_admin_secret_obj
      @admin_secret_obj = AdminSecret.get_from_memcache(@admin.admin_secret_id)

      success
    end

    # Validate Otp
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @new_admin_obj
    #
    # @return [Result::Base]
    #
    def validate_otp
      r = @admin_secret_obj.ga_secret_decrypted
      ga_secret_d = r.data[:plaintext]
      rotp_obj = TimeBasedOtp.new(ga_secret_d)
      r = rotp_obj.verify_with_drift_and_prior(@otp, @admin.last_otp_at)
      return error_with_identifier('invalid_api_params',
                                   'cm_uda_vo_1',
                                   ['invalid_otp'],
                                   ''
      ) unless r.success?

      success
    end

    # Get Encrypted Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def get_encrypted_ethereum_deposit_address
      encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.ethereum_deposit_address_secret_key)
      r = encryptor_obj.encrypt(@ethereum_deposit_address)
      fail r unless r.success?

      r.data[:ciphertext_blob]
    end

    # Get Decrypted Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def get_decrypted_ethereum_deposit_address(ethereum_deposit_address)
      return "" if ethereum_deposit_address.blank?

      encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.ethereum_deposit_address_secret_key)
      r = encryptor_obj.decrypt(ethereum_deposit_address)
      fail r unless r.success?

      r.data[:plaintext]
    end

    # Update Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def update_ethereum_deposit_address
      if @ethereum_deposit_address.blank?
        @client_token_sale_details.ethereum_deposit_address = nil
      else
        @client_token_sale_details.ethereum_deposit_address = get_encrypted_ethereum_deposit_address
      end
      @client_token_sale_details.logged_admin_id = @admin_id
      @client_token_sale_details.source = GlobalConstant::AdminActivityChangeLogger.web_source

      @client_token_sale_details.save! if @client_token_sale_details.changed?
    end

    # Send email
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    def send_email
      # send to all super admins
      # Email::HookCreator::SendTransactionalMail.new(
      #     client_id: @client.id,
      #     email: @admin.email,
      #     template_name: GlobalConstant::PepoCampaigns.kyc_issue_template,
      #     template_vars: {}
      # ).perform
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          ethereum_deposit_address: @ethereum_deposit_address
      }
    end

  end
end