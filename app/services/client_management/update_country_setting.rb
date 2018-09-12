module ClientManagement
  class UpdateCountrySetting < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Array] blacklisted_countries (optional) - blacklisted_countries Array
    # @param [Array] residency_proof_nationalities (optional) - residency_proof_nationalities Array
    #
    # @return [ClientManagement::UpdateCountrySetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @blacklisted_countries = @params[:blacklisted_countries] || []
      @residency_proof_nationalities = @params[:residency_proof_nationalities] || []

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

      update_country_setting

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

      r = validate_country_and_nationality
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

    # Country and Nationality validate
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @countries, @nationalities
    #
    def validate_country_and_nationality

      # Countries list is always in upcase
      @blacklisted_countries = @blacklisted_countries.compact.uniq.sort
      @residency_proof_nationalities = @residency_proof_nationalities.compact.uniq.sort

      @countries = GlobalConstant::CountryNationality.countries
      is_countries_present = @blacklisted_countries - @countries
      return error_with_data(
          'cm_ucs_vcan_1',
          "Invalid Country: #{is_countries_present} selected",
          'Invalid Country',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if is_countries_present.present?

      # Nationalities list is always in upcase
      @nationalities = GlobalConstant::CountryNationality.nationalities
      is_nationalities_present = @residency_proof_nationalities - @nationalities

      return error_with_data(
          'cm_ucs_vcan_2',
          "Invalid Nationality: #{is_nationalities_present} selected",
          'Invalid Nationality',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if is_nationalities_present.present?

      success
    end

    # Update Country Setting
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_kyc_config_details
    #
    def update_country_setting
      @client_kyc_config_details = ClientKycConfigDetail.get_from_memcache(@client_id)
      @client_kyc_config_details.residency_proof_nationalities = @residency_proof_nationalities
      @client_kyc_config_details.blacklisted_countries = @blacklisted_countries

      @client_kyc_config_details.save! if @client_kyc_config_details.changed?
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
      {}
    end

  end
end