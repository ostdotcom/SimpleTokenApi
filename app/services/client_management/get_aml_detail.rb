module ClientManagement

  class GetAmlDetail < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::GetAmlDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client_cynopsyis = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch_aml_details

      success_with_data(success_response_data)
    end

    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By: Aman
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # Sets @client, @admin
    #
    def validate_client_and_admin

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Fetch Aml Details
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # Sets @client_aml_details
    #
    def fetch_aml_details
      @client_aml_details = ClientAmlDetail.get_from_memcache(@client_id)
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 25/09/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          aml_login_url: @client_aml_details.base_url,
          aml_username: @client_aml_details.email_id
      }
    end

  end
end

