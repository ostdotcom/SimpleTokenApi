module AdminManagement

  module Profile

    class GetDetail < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @params [String] admin_id (mandatory) - admin id
      # @params [String] client_id (mandatory) - this is the client id
      #
      # @return [AdminManagement::Profile::GetDetail]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]

        @client, @client_kyc_config_detail_obj = nil, nil
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        fetch_client

        fetch_admin

        fetch_kyc_config_detail

        success_with_data(success_response_data)

      end

      private

      # Fetch Client
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # Sets @client
      #
      def fetch_client
        @client = Client.get_from_memcache(@client_id)
      end


      # Fetch Admin
      #
      # * Author: Aman
      # * Date: 18/04/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      def fetch_admin
        @admin = Admin.get_from_memcache(@admin_id)
      end

      # Fetch token sale details
      #
      # * Author: Aman
      # * Date: 16/08/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_config_detail_obj
      #
      def fetch_kyc_config_detail
        @client_kyc_config_detail_obj = ClientKycConfigDetail.get_from_memcache(@client_id)
      end

      # Api response data
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # returns [Hash] api response data
      #
      def success_response_data
        {
            client_setup: {
                has_email_setup: @client.is_email_setup_done?,
                has_whitelist_setup: @client.is_whitelist_setup_done?,
                web_host_setup_done: @client.is_web_host_setup_done?
            },
            admin: {
                email: @admin.email,
                name: @admin.name,
                role: @admin.role
            },
            kyc_config_detail: {
                has_ethereum_address_field: @client_kyc_config_detail_obj.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field)
            }
        }
      end

    end

  end

end