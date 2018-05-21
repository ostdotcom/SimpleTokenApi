module UserManagement
  module ContactUsPipeDrive
    class Base < ServicesBase

      # Initialize
      #
      # @params
      #
      # @return [UserManagement::ContactUsPipeDrive::Base]
      #
      def initialize(params)
        super
      end

      # Create a pipe drive deal
      #
      # @return [Result::Base]
      #
      def create_pipe_drive_deal
        request_params = {
            title: @company || @company_website,
            person_id: @full_name + ' ' + @email,
            org_id: @company || @company_website
        }

        request_params[GlobalConstant::PipeDrive::project_description_key] = @project_description if @project_description
        request_params[GlobalConstant::PipeDrive::token_sale_start_date_key] = @token_sale_start_date if @token_sale_start_date
        request_params[GlobalConstant::PipeDrive::token_sale_end_date_key] = @token_sale_end_date if @token_sale_end_date
        request_params[GlobalConstant::PipeDrive::need_front_end_key] = @need_front_end if @need_front_end
        request_params[GlobalConstant::PipeDrive::applicant_volume_key] = @applicant_volume if @applicant_volume
        request_params[GlobalConstant::PipeDrive::company_website_key] = @company_website if @company_website

        path = GlobalConstant::PipeDrive::deals_end_point + "?api_token=#{GlobalConstant::Base.pipedrive['api_secret']}"

        pipe_drive_request = PipeDrive::HttpHelper.new()

        r = pipe_drive_request.send_request_of_type('post', path, request_params)
        return r unless r.success?

        success
      end

    end
  end
end
