module ClientManagement

  class GetProfileDetails < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::GetProfileDetails.new()]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]

      @client = nil
      @client_web_host = nil
      @client_super_admin_email = nil

    end


    # Perform
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client
      fetch_client_web_host
      fetch_client_super_admin

      success_with_data(success_response_data)
    end

    private

    # Fetch Client
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    def fetch_client
      @client = Client.get_from_memcache(@client_id)
    end

    # Fetch Client Web Host
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
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
    # * Reviewed By:
    #
    # Sets @client_super_admin
    #
    def fetch_client_super_admin
      @client_super_admin_email = Admin.client_super_admin_emails(@client_id)
    end


    # Api response data
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          name: @client.name,
          domain_name: @client_web_host.domain,
          super_admin_email_id: @client_super_admin_email
      }
    end

  end

end
