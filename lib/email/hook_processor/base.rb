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

        r = fetch_client_details
        return r unless r.success?

        process_hook

      end

      # Fetch client and client_pepo_campaign_detail_obj
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # Sets @client, @client_pepo_campaign_detail_obj, @campaign_api_secret_d, @campaign_api_key
      #
      # @return [Result::Base]
      #
      def fetch_client_details
        if is_ost_kyc_default_client?
          @campaign_api_key = GlobalConstant::PepoCampaigns.api_key
          @campaign_api_secret_d = GlobalConstant::PepoCampaigns.api_secret
          success
        else
          @client = Client.get_from_memcache(@hook.client_id)
          @client_pepo_campaign_detail_obj = ClientPepoCampaignDetail.get_from_memcache(@hook.client_id)
          @campaign_api_key = @client_pepo_campaign_detail_obj.api_key
          decrypt_api_secret
        end
      end

      private

      # Decrypt api secret
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # Sets @campaign_api_secret_d
      #
      # @return [Result::Base]
      #
      def decrypt_api_secret
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        api_salt_d = r.data[:plaintext]

        r = LocalCipher.new(api_salt_d).decrypt(@client_pepo_campaign_detail_obj.api_secret)
        return r unless r.success?

        @campaign_api_secret_d = r.data[:plaintext]

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
            @hook.params[:list_id],
            @hook.email,
            attributes_hash,
            user_settings_hash
        ]
      end

      # builds params which go into API call to Email Service for send transactional email
      #
      # * Author: Aman
      # * Date: 13/11/2018
      # * Reviewed By:
      #
      # @return [Array]
      #
      def send_transactional_mail_params
        [
            @hook.email,
            @hook.params[:template_name],
            @hook.params[:template_vars].merge(web_host_params)
        ]
      end

      # send the web host domain of kyc clients if front end solution has been taken
      #
      # * Author: Aman
      # * Date: 13/11/2018
      # * Reviewed By:
      #
      # @return [Array]
      #
      def web_host_params
        return {} if is_ost_kyc_default_client? || !@client.is_web_host_setup_done?
        cwd = ClientWebHostDetail.get_from_memcache_by_client_id(@client.id)

        {
            web_host_domain: cwd.domain
        }
      end

      # pepo campaign klass
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Object] Email::Services::PepoCampaigns
      def pepo_campaign_obj
        Email::Services::PepoCampaigns.new(api_key: @campaign_api_key, api_secret: @campaign_api_secret_d)
      end

      # check if the pepo campaign acoount to be used is the default kyc account
      #
      # * Author: Aman
      # * Date: 13/11/2018
      # * Reviewed By:
      #
      # @return [Boolean] True if client is the default kyc client
      #
      def is_ost_kyc_default_client?
        @hook.client_id == Client::OST_KYC_CLIENT_IDENTIFIER
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