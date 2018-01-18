module UserManagement

  class ContactUs < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    # @params [String] full_name (mandatory) - full name
    # @params [Integer] company (mandatory) - company
    # @params [Integer] email (mandatory) - email
    # @params [String] contact_number (mandatory) - contact_number
    # 
    # @return [UserManagement::ContactUs]
    #
    def initialize(params)
      super

      @full_name = @params[:full_name]
      @company = @params[:company]
      @email = @params[:email]
      @contact_number = @params[:contact_number]

      @error_data = {}
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      r = send_contact_us_admin_email
      return r unless r.success?

      success
    end

    private

    # Validate
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      @full_name = @full_name.to_s.strip
      @company = @company.to_s.strip
      @email = @email.to_s.strip
      @contact_number = @contact_number.to_s.strip

      @error_data[:full_name] = 'Full Name is required.' if !@full_name.present?
      @error_data[:company] = 'Company is required.' if !@company.present?
      @error_data[:contact_number] = 'Contact Number is required.' if !@contact_number.present?
      @error_data[:contact_number] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)

      return error_with_data(
          'um_cu_1',
          '',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          @error_data
      ) if @error_data.present?

      success
    end

    # Send email
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    def send_contact_us_admin_email
      Email::HookCreator::SendTransactionalMail.new(
          client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
          email: GlobalConstant::Email.contact_us_admin_email,
          template_name: GlobalConstant::PepoCampaigns.contact_us_template,
          template_vars: {
              subject: subject,
              body: body
          }
      ).perform
    end

    # Subject
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    def subject
      "#{GlobalConstant::Email.subject_prefix}Partner Companies - Contact Us - #{@email}"
    end

    # Contact US body
    #
    # * Author: Aman
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    def body
      "<p> Email : #{@email}<br/>
      Name : #{@full_name}<br/>
      Company : #{@company}<br/>
      Contact Number : #{@contact_number}</p>"
    end

  end

end
