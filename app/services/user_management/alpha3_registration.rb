module UserManagement

  class Alpha3Registration < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @params [String] first_name (mandatory) - first name
    # @params [String] last_name (mandatory) - last name
    # @params [String] company_name (mandatory) - company name
    # @params [String] email (mandatory) - email
    # @params [String] project_description (Optional) - Project description
    # @params [Integer] kit_marketing (Optional) - kit marketing emails selected
    #
    # @return [UserManagement::Alpha3Registration]
    #
    def initialize(params)
      super

      @first_name = @params[:first_name].to_s.strip
      @last_name = @params[:last_name].to_s.strip
      @email = @params[:email].to_s.strip
      @company_name = @params[:company_name].to_s.strip
      @project_description = @params[:project_description].to_s.strip
      @kit_marketing = @params[:kit_marketing].to_i
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
      error_data[:first_name] = 'First Name is required.' if @first_name.blank?
      error_data[:last_name] = 'Last Name is required.' if @last_name.blank?
      error_data[:company_name] = 'Company / Project name is required.' if @company_name.blank?
      error_data[:email] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)
      error_data[:project_description] = 'Project Description is required.' if @project_description.blank?
      error_data[:project_description] = 'Project Description cannot be more than 1000 characters.' if @project_description.length > 1000

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
          GlobalConstant::PepoCampaigns.first_name_attribute => @first_name,
          GlobalConstant::PepoCampaigns.last_name_attribute => @last_name,
          GlobalConstant::PepoCampaigns.company_name_attribute => @company_name
      }

      custom_attributes[GlobalConstant::PepoCampaigns.project_description_attribute] = @project_description if @project_description.present?
      custom_attributes[GlobalConstant::PepoCampaigns.kit_marketing_attribute] = @kit_marketing

      Email::HookCreator::AddContact.new(
          client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
          email: @email,
          custom_attributes: custom_attributes,
          list_id: GlobalConstant::PepoCampaigns.alpha_3_list_id
      ).perform

    end

  end

end