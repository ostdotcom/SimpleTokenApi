module UserManagement
  module ContactUsPipeDrive

    class Partner < Base
      # Initialize
      #
      # @params [String] full_name (mandatory) - full name
      # @params [String] company_website (mandatory) - company website
      # @params [Integer] email (mandatory) - email
      # @params [String] project_description (mandatory) - Project description
      #
      # @return [UserManagement::ContactUsPipeDrive::Partner]
      #
      def initialize(params)
        super

        @full_name = @params[:full_name]
        @company_website = @params[:company_website]
        @email = @params[:email]
        @project_description = @params[:project_description]

        @error_data = {}
      end

      # Validate
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        @full_name = @full_name.to_s.strip
        @company_website = @company_website.to_s.strip
        @email = @email.to_s.strip

        @error_data[:full_name] = 'Full Name is required.' if !@full_name.present?
        @error_data[:email] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)

        return error_with_data(
            'um_cupd_p_1',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            @error_data
        ) if @error_data.present?

        success
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

    end
  end
end
