module Email

  module HookProcessor

    class Base

      include Util::ResultHelper

      # Initialize
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @param [EmailServiceApiCallHook] hook (mandatory) - db record of EmailServiceApiCallHook table
      #
      # @return [Email::HookProcessor::Base] returns an object of Email::HookProcessor::Base class
      #
      def initialize(hook)
        @hook = hook
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform

        r = validate
        return r unless r.success?

        fetch_client_details

        r = decrypt_api_secret
        return r unless r.success?

        process_hook

      end

      # Fetch client and client_pepo_campaign_detail_obj
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # Sets @client, @client_pepo_campaign_detail_obj
      #
      # @return [Result::Base]
      #
      def fetch_client_details
        @client = Client.get_from_memcache(@hook.client_id)
        @client_pepo_campaign_detail_obj = ClientPepoCampaignDetail.get_from_memcache(@hook.client_id)
      end

      private

      # Decrypt api secret
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # Sets @api_secret_d
      #
      # @return [Result::Base]
      #
      def decrypt_api_secret
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        api_salt_d = r.data[:plaintext]

        r = LocalCipher.new(api_salt_d).decrypt(@client_pepo_campaign_detail_obj.api_secret)
        return r unless r.success?

        @api_secret_d = r.data[:plaintext]

        success
      end

      # sub classes to implement logic of validating here
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate
        fail 'sub class to implement'
      end

      # sub classes to implement logic of processing hook here
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook
        fail 'sub class to implement'
      end

      # builds params which go into API call to Email Service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Array]
      #
      def add_update_contact_params
        [
            GlobalConstant::PepoCampaigns.master_list_id,
            @hook.email,
            attributes_hash,
            user_settings_hash
        ]
      end

      # pepo campaign klass
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Object] Email::Services::PepoCampaigns
      def pepo_campaign_obj
        Email::Services::PepoCampaigns.new(api_key: @client_pepo_campaign_detail_obj.api_key, api_secret: @api_secret_d)
      end

      # Build attributes for email service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def attributes_hash
        fail 'sub class to implement'
      end

      # Build user settings for email service
      #
      # * Author: Puneet
      # * Date: 11/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def user_settings_hash
        fail 'sub class to implement'
      end

    end

  end

end