module ClientManagement
  class ResetApiCredentials < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::ResetApiCredentials]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client_api_secret_d = nil
      @client_api_detail = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = reset_client_api_credentials
      return r unless r.success?

      success_with_data(success_response_data)
    end


    # private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = fetch_and_validate_client_api_details
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 27/08/2018
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

    # Fetch Client Api detail row
    #
    # * Author: Aman
    # * Date: 20/02/2019
    # * Reviewed By:
    #
    # Sets @client_api_detail
    #
    def fetch_and_validate_client_api_details
      @client_api_detail = ClientApiDetail.non_deleted.where(client_id: @client_id).last

      return error_with_identifier('invalid_client_id', 'cm_rac_favcad_1') if @client_api_detail.blank? ||
          (@client_api_detail.status != GlobalConstant::ClientApiDetail.active_status)

      success
    end

    # Reset Client Api Credentials
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets  @client_api_secret_d
    #
    # @return [Result::Base]
    #
    def reset_client_api_credentials

      r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
      return r unless r.success?

      api_salt_d = r.data[:plaintext]

      @client_api_secret_d = Utility.generate_random_id

      r = LocalCipher.new(api_salt_d).encrypt(@client_api_secret_d)
      return r unless r.success?

      api_secret_e = r.data[:ciphertext_blob]
      api_key = Utility.generate_random_id

      @client_api_detail.api_key = api_key
      @client_api_detail.api_secret = api_secret_e
      @client_api_detail.save!
      success
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          api_key: @client_api_detail.api_key,
          api_secret: @client_api_secret_d
      }
    end

  end
end