module UserManagement
  module ContactUsPipeDrive
    class Base < ServicesBase

      # Initialize
      #
      # @params [String] full_name (mandatory) - full name
      # @params [String] company (mandatory) - company
      # @params [Integer] email (mandatory) - email
      # @params [Date] token_sale_start_date (mandatory) - token sale start date
      # @params [Date] token_sale_end_date (mandatory) - token sale end date
      # @params [Boolean] need_front_end (mandatory) - Need a custom front end
      # @params [Integer] applicant_volume (mandatory) - Applicant volume
      # @params [String] project_description (mandatory) - Project description
      #
      # @return [UserManagement::ContactUsPipeDrive::Base]
      #
      def initialize(params)
        super

        @full_name = @params[:full_name]
        @company = @params[:company]
        @email = @params[:email]
        @token_sale_start_date = @params[:token_sale_start_date]
        @token_sale_end_date = @params[:token_sale_end_date]
        @need_front_end = @params[:need_front_end]
        @applicant_volume = @params[:applicant_volume]
        @project_description = @params[:project_description]

        @error_data = {}
      end

      # Perform
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
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
        @token_sale_start_date = @token_sale_start_date.to_s.strip
        @token_sale_end_date = @token_sale_end_date.to_s.strip

        @error_data[:full_name] = 'Full Name is required.' if !@full_name.present?
        @error_data[:company] = 'Company is required.' if !@company.present?
        @error_data[:email] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)
        @error_data[:token_sale_start_date] = 'Token sale start date is required.' if !@token_sale_start_date.present?
        @error_data[:token_sale_end_date] = 'Token sale end date is required.' if !@token_sale_end_date.present?
        @error_data[:need_front_end] = 'Please provide info whether custom front-end is required or not' if !@need_front_end.present?
        @error_data[:applicant_volume] = 'Applicant volume is required.' if !@applicant_volume.present?

        @error_data[:token_sale_start_date] = 'Start date cannot be later than end date' if @token_sale_end_date < @token_sale_start_date

        return error_with_data(
            'um_pcu_b_1',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            @error_data
        ) if @error_data.present?

        success
      end

      # Create a pipe drive deal
      #
      # return [Result::Base]
      #
      def create_pipe_drive_deal
        request_params = {
            title: @company,
            person_id: @full_name + ' ' + @email,
            org_id: @company
        }

        request_params[GlobalConstant::PipeDrive::project_description_key] = @project_description
        request_params[GlobalConstant::PipeDrive::token_sale_start_date_key] = @token_sale_start_date
        request_params[GlobalConstant::PipeDrive::token_sale_end_date_key] = @token_sale_end_date
        request_params[GlobalConstant::PipeDrive::need_front_end_key] = @need_front_end
        request_params[GlobalConstant::PipeDrive::applicant_volume_key] = @applicant_volume

        path = GlobalConstant::PipeDrive::deals_end_point + "?api_token=#{GlobalConstant::Base.pipedrive['api_secret']}"

        pipe_drive_request = PipeDrive::HttpHelper.new()

        r = pipe_drive_request.send_request_of_type('post', path, request_params)
        return r unless r.success?

        success
      end

    end
  end
end
