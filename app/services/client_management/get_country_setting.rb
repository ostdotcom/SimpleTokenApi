module ClientManagement
  class GetCountrySetting < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::GetCountrySetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]

      @client_kyc_config_details = nil

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

      get_country_setting

      success_with_data(success_response_data)
    end


    private

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

      r = fetch_and_validate_client
      return r unless r.success?

      success
    end

    # Get Country Setting
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_kyc_config_details
    #
    def get_country_setting
      @client_kyc_config_details = @client.client_kyc_config_detail
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
          countires: GlobalConstant::CountryNationality.countries,
          nationalities: GlobalConstant::CountryNationality.nationalities,
          blacklisted_countries: @client_kyc_config_details.blacklisted_countries,
          residency_proof_nationalities: @client_kyc_config_details.residency_proof_nationalities
      }
    end

  end
end