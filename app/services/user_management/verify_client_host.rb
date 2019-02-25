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
      @client = nil
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
          client_id: @client_id,
          client: @client
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


      if client_web_host_detail_obj.blank? || (client_web_host_detail_obj.status !=
          GlobalConstant::ClientWebHostDetail.active_status)

        res = error_with_internal_code('um_vch_1',
                                       'invalid domain',
                                       GlobalConstant::ErrorCode.temporary_redirect,
                                       {},
                                       {},
                                       {}
        )

        redirect_url = GlobalConstant::KycApiBaseDomain.get_base_domain_url_for_environment(Rails.env)
        redirect_url = client_web_host_detail_obj.redirect_url if client_web_host_detail_obj.present?
        res.set_error_extra_info({redirect_url: redirect_url})
        return res
      end

      @client_id = client_web_host_detail_obj.client_id
      @client = Client.get_from_memcache(@client_id)

      return unauthorized_access_response('um_vch_2') if @client.blank? ||
          (@client.status != GlobalConstant::Client.active_status)

      success
    end

  end

end