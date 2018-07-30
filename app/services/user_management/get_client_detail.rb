module UserManagement

  class GetClientDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [String] template_type (mandatory) - this is the page template name
    #
    # @return [UserManagement::GetClientDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @template_type = @params[:template_type]

      @client = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_client_details
      return r unless r.success?

      r = fetch_client_data_from_cache
      return r unless r.success?

      success_with_data(r.data)
    end

    private

    # validate and sanitize params data
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      @template_type = @template_type.to_s.strip

      r = validate
      return r unless r.success?

      return error_with_data(
          'um_gcd_1',
          'Invalid Template Type',
          'Invalid Template Type',
          GlobalConstant::ErrorAction.default,
          {}
      ) if [
          GlobalConstant::ClientTemplate.login_template_type,
          GlobalConstant::ClientTemplate.sign_up_template_type,
          GlobalConstant::ClientTemplate.reset_password_template_type,
          GlobalConstant::ClientTemplate.change_password_template_type,
          GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type,

          GlobalConstant::ClientTemplate.kyc_template_type,
          GlobalConstant::ClientTemplate.dashboard_template_type,
          GlobalConstant::ClientTemplate.verification_template_type
      ].exclude?(@template_type)

      success
    end

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_gbd_1',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

    # Fetch clients setting and page setting data from cache
    #
    # * Author: Aman
    # * Date: 15/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_data_from_cache
      ClientSetting.new(@client_id, @template_type).perform
    end

  end

end