module UserManagement

  class VerifyClientHost < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @param [String] domain (mandatory) - this is the request domain
    #
    # @return [UserManagement::VerifyClientHost]
    #
    def initialize(params)
      super

      @domain = @params[:domain]

      @client_id = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = fetch_client_details
      return r unless r.success?

      success_with_data(
          client_id: @client_id
      )

    end

    private

    # Set client id from domain
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client_id
    #
    # @return [Result::Base]
    #
    def fetch_client_details
      client_web_host_detail_obj = ClientWebHostDetail.get_from_memcache_by_domain(@domain)
      return unauthorized_access_response('um_vch_1') if client_web_host_detail_obj.blank?

      return unauthorized_access_response('um_vch_2') if (client_web_host_detail_obj.status !=
          GlobalConstant::ClientWebHostDetail.active_status)

      @client_id = client_web_host_detail_obj.client_id

      success
    end

  end

end