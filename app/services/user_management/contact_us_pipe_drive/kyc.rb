module UserManagement
  module ContactUsPipeDrive

    class Kyc < Base

      # Initialize
      #
      # @params [String] full_name (mandatory) - full name
      # @params [String] company (mandatory) - company
      # @params [String] email (mandatory) - email
      # @params [Integer] ost_product_communicate (mandatory) - option for product related communications
      # @params [String] project_description (optional) - Project description
      # @params [Integer] ost_market_communicate (optional) - option for marketing communication
      # @return [UserManagement::ContactUsPipeDrive::Kyc]
      #
      def initialize(params)
        super

        @full_name = @params[:full_name]
        @company = @params[:company]
        @email = @params[:email]
        @project_description = @params[:project_description]
        @utm_params = @params[:utm_params] || {}
        @ost_product_communicate = @params[:ost_product_communicate]
        @ost_market_communicate = @params[:ost_market_communicate]

        @error_data = {}
      end

      # Perform
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        build_request_params

        r = handle_email_preferences
        return r unless r.success?

        r = create_pipe_drive_deal
        return r unless r.success?

        success
      end

      private

      # Validate
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize

        @full_name = @full_name.to_s.strip
        @company = @company.to_s.strip
        @email = @email.to_s.strip

        @project_description = @project_description.to_s.strip
        @ost_product_communicate = @ost_product_communicate.to_i
        @ost_market_communicate = @ost_market_communicate.to_i

        @error_data[:full_name] = 'Full Name is required.' if !@full_name.present?
        @error_data[:company] = 'Company is required.' if !@company.present?
        @error_data[:email] = 'Please enter a valid email address' unless Util::CommonValidateAndSanitize.is_valid_email?(@email)
        @error_data[:ost_product_communicate] = 'Please provide valid option for product communications' if @ost_product_communicate != 1

        return error_with_data(
            'um_cupd_k_1',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            @error_data
        ) if @error_data.present?

        success
      end

      def handle_email_preferences

        r = Email::HookCreator::AddContact.new(
              email: @email,
              client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
              custom_attributes: { GlobalConstant::PepoCampaigns.kyc_marketing_attribute => @ost_market_communicate },
              list_id: GlobalConstant::PepoCampaigns.kyc_product_list_id
            ).perform

        return r unless r.success?
        success
      end

      def build_request_params
        @request_params = {
            title: @company,
            person_id: @full_name + ' ' + @email,
            org_id: @company,
            stage_id: GlobalConstant::Base.pipedrive['kyc_init_stage_id']
        }

        @request_params[GlobalConstant::Base.pipedrive['project_description_key']] = @project_description
        @request_params[GlobalConstant::Base.pipedrive['utm_source_key']] = @utm_params[:utm_source]
        @request_params['user_id'] = GlobalConstant::Base.pipedrive['default_kyc_deal_owner']

        @request_params
      end

    end
  end
end
