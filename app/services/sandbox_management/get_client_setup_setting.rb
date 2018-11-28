module SandboxManagement

  class GetClientSetupSetting < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 08/08/2018
    # * Reviewed By:
    #
    # @params [Hash] decoded_token_data (mandatory) - it contains uuid of the client
    #
    # @return [SandboxManagement::GetClientSetupSetting]
    #
    def initialize(params)
      super
      @decoded_token_data = @params[:decoded_token_data]
      @uuid = @decoded_token_data[:uuid]

      @client_id = nil
      @client_setting = {}
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = get_client_settings
      return r unless r.success?

      success_with_data(success_response_data)

    end

    private

    # Validate
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate
      r = super
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      success
    end

    # fetch client and validate
    #
    # * Author: Aman
    # * Date: 26/12/2017
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def fetch_and_validate_client
      sandbox_uuid = "#{GlobalConstant::Client.sandbox_prefix_uuid}#{@uuid}"
      @client = Client.where(uuid: sandbox_uuid).first

      return error_with_identifier("invalid_client_id", "am_cc_gpd_favc_1") if @client.blank? ||
          @client.status != GlobalConstant::Client.active_status

      @client_id = @client.id
      success
    end

    # Get Published Draft
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # Sets @client_setting
    #
    def get_client_settings
      cp = ClientPlan.get_client_plan_from_memcache(@client_id)
      aml = ClientAmlDetail.get_from_memcache(@client_id)
      pepo_campaign = ClientPepoCampaignDetail.get_from_memcache(@client_id)
      web_host = ClientWebHostDetail.get_from_memcache_by_client_id(@client_id)
      token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@client_id)
      kyc_config_detail = ClientKycConfigDetail.get_from_memcache(@client_id)
      super_admins = Admin.where(default_client_id: @client_id, role: GlobalConstant::Admin.super_admin_role).not_deleted.all

      super_admins_data = super_admins.map {|x|
        {
            email: x.email,
            password: Utility.generate_random_id,
            name: x.name
        }
      }

      @client_setting = {
          client_plan: {
              add_ons: cp.add_ons_array,
              kyc_submissions_count: cp.kyc_submissions_count
          },
          super_admins: super_admins_data,
          double_opt_in: @client.is_verify_page_active_for_client?,
          client_name: @client.name,
          aml: {
              email_id: aml.email_id,
              domain_name: aml.domain_name,
              token: decrypted_value(aml.token),
              base_url: aml.base_url
          },
          pepo_campaign: {
              api_key: pepo_campaign.api_key,
              api_secret: decrypted_value(pepo_campaign.api_secret)
          },
          token_sale_details: {
              token_name: token_sale_detail.token_name,
              token_symbol: token_sale_detail.token_symbol,
              sale_start_timestamp: token_sale_detail.sale_start_timestamp,
              registration_end_timestamp: token_sale_detail.registration_end_timestamp,
              sale_end_timestamp: token_sale_detail.sale_end_timestamp,
          },
          kyc_config: {
              kyc_fields: kyc_config_detail.kyc_fields_array,
              residency_proof_nationalities: kyc_config_detail.residency_proof_nationalities,
              blacklisted_countries: kyc_config_detail.blacklisted_countries
          }
      }

      if web_host.present?
        @client_setting[:web_host] = {
            domain: web_host.domain
        }

        r = SandboxManagement::CmsConfigurator::GetPublishedDraft.new(
            {decoded_token_data: {uuid: @uuid}}).perform
        return r unless r.success?

        @client_setting[:entity_type_and_data_hash] = r.data[:entity_type_and_data_hash]
      end

      success

    end

    # decrypted key using local cipher
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # returns [String]  decrypted key value
    #
    def decrypted_value(key)
      r = LocalCipher.new(client_salt_decrypted).decrypt(key)
      fail "unable to decrypt key" unless r.success?
      r.data[:plaintext]
    end

    # decrypted salt of client
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # returns [String] Client salt decrypted using kms
    #
    def client_salt_decrypted
      @client_salt_decrypted ||= begin
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        fail "unable to decrypt client data" unless r.success?

        r.data[:plaintext]
      end
    end

    # Api response data
    #
    # * Author: Aman
    # * Date: 12/11/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          client_setting: @client_setting
      }
    end

  end

end
