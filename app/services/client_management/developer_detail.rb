module ClientManagement

    class DeveloperDetail < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @param [Integer] admin_id (mandatory) -  admin id
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::DeveloperDetail.new()]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @client = nil
        @api_secret_d = nil
        @client_cynopsyis = nil


      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_client_and_admin
        return r unless r.success?

        fetch_client
        fetch_api_keys
        fetch_client_cynopsis

        success_with_data(success_response_data)

      end

      private

      # Client and Admin validate
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # Sets @client
      #
      def validate_client_and_admin
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        admin = fetch_admin

        return error_with_data(
            's_cm_pd_1',
            'client_id is not equal to default client_id',
            'client_id is not equal to default client_id',
            GlobalConstant::ErrorAction.default,
            {}
        ) if admin.default_client_id != @client_id

        success

      end

      # Fetch admin
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # Sets @client
      #
      def fetch_admin
        Admin.get_from_memcache(@admin_id)
      end

      # Fetch Client
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # Sets @client
      #
      def fetch_client
        @client = Client.get_from_memcache(@client_id)
      end

      # Fetch Secret Decrypt
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # Sets @api_secret_d
      #
      def fetch_api_keys
        api_salt_d =  Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt).data[:plaintext]

        @api_secret_d = LocalCipher.new(api_salt_d).decrypt(@client.api_secret).data[:plaintext]
      end

      # Fetch Client Cynopsis
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # Sets @client_cynopsis
      #
      def fetch_client_cynopsis
        @client_cynopsis = ClientCynopsisDetail.get_from_memcache(@client_id)
      end


      # Api response data
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # returns [Hash] api response data
      #
      def success_response_data
        {
            api_key: @client.api_key,
            api_secret: @api_secret_d,
            aml_login_url: @client_cynopsis.base_url,
            aml_username: @client_cynopsis.username,
            meta:{
                env:Rails.env
            }
        }
      end

    end
end
