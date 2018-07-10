module UserManagement

  class Alpha3Registration < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @params [String] company_name (mandatory) - company name
    # @params [String] email (mandatory) - email
    # @params [String] country (mandatory) - Country
    # @params [Integer] alpha2_participant (mandatory) - participated in alpha 2
    #
    # @return [UserManagement::Alpha3Registration]
    #
    def initialize(params)
      super

      @email = @params[:email].to_s.strip
      @company_name = @params[:company_name].to_s.strip
      @country = @params[:country].to_s.strip
      @alpha2_participant = @params[:alpha2_participant].to_i
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      create_email_service_api_call_hook

      success
    end

    private

    # Validate
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      error_data = {}
      error_data[:country] = 'Country is required.' if @country.blank?
      error_data[:company_name] = 'Company name is required.' if @company_name.blank?
      error_data[:email] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)

      return error_with_data(
          'um_cupd_p_1',
          '',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          error_data
      ) if error_data.present?

      success
    end

    # Create Hook to sync data in Email Service
    #
    # * Author: Pankaj
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    def create_email_service_api_call_hook

      custom_attributes = {
          GlobalConstant::PepoCampaigns.country_attribute => @country,
          GlobalConstant::PepoCampaigns.alpha2_participant_attribute => @alpha2_participant,
          GlobalConstant::PepoCampaigns.company_name_attribute => @company_name
      }

      Email::HookCreator::AddContact.new(
          client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
          email: @email,
          custom_attributes: custom_attributes,
          list_id: GlobalConstant::PepoCampaigns.alpha_3_list_id
      ).perform

    end

  end

end