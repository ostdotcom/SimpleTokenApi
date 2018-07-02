module ClientManagement

    class DeveloperDetail < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @params [String] admin_id (mandatory) - this is the email entered
      # @params [String] client_id (mandatory) - this is the client id
      #
      # @return [ClientManagement::DeveloperDetail]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]

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

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        fetch_client
        fetch_secret_decrypt
        fetch_client_cynopsis

        success_with_data(success_response_data)

      end

      private

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
      def fetch_secret_decrypt
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
