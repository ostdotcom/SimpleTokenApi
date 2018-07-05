module ClientManagement

  class GetProfileDetails < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::GetProfileDetails]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client = nil
      @client_web_host = nil
      @client_super_admin_emails = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      fetch_client_web_host
      fetch_client_super_admin_emails

      success_with_data(success_response_data)
    end

    private

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @client
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # todo: which domain name
    #
    # Fetch Client Web Host
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @client_web_host
    #
    def fetch_client_web_host
      @client_web_host = ClientWebHostDetail.get_from_memcache_by_client_id(@client_id)
    end

    # Fetch Client Super Admin
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @client_super_admin_emails
    #
    def fetch_client_super_admin_emails
      @client_super_admin_emails = Admin.client_super_admin_emails(@client_id)
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          name: @client.name,
          domain_name: @client_web_host.domain,
          super_admin_email_ids: @client_super_admin_emails
      }
    end

  end

end
