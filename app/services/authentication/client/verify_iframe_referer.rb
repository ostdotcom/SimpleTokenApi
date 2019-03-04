module Authentication
  module Client

    class VerifyIframeReferer < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 01/02/2018
      # * Reviewed By:
      #
      # @param [String] referer_host (mandatory) - this is the domain in which iframe was loaded
      #
      # @return [Authentication::Client::VerifyIframeReferer]
      #
      def initialize(params)
        super

        @referer_host = @params[:referer_host]
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


        if client_web_host_detail_obj.blank? || (client_web_host_detail_obj.status !=
            GlobalConstant::ClientWebHostDetail.active_status)
          return error_with_identifier('invalid_or_expired_token', 'a_c_vir_fcd_1')
        end

        @client_id = client_web_host_detail_obj.client_id

        success
      end
    end

  end
end