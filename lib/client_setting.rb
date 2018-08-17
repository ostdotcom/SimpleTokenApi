class ClientSetting

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Aman
  # * Date: 15/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  # @param [String] entity_type - entity type for page draft
  # @param [Integer] entity_group_id - Entity group id for which preview draft has to be fetched.
  #
  # @return [ClientSetting]
  #
  def initialize(client_id, entity_type, entity_group_id=0)
    @client_id = client_id
    @entity_type = entity_type
    @entity_group_id = entity_group_id

    @client_setting = nil
    @page_setting = nil
    @response_data = {}
  end

  # Perform
  #
  # * Author: Aman
  # * Date: 15/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def perform
    r = fetch_client_setting_data
    return r unless r.success?

    success_with_data(r.data)
  end

  private

  # Fetch clients settings data from cache
  #
  # * Author: Aman
  # * Date: 15/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_published_client_setting_data_from_memcache
    memcache_key_object = MemcacheKey.new('client.client_setting_detail')
    memcache_template_key = memcache_key_object.key_template % {client_id: @client_id, entity_type: @entity_type}

    r = Memcache.get_set_memcached(memcache_template_key, memcache_key_object.expiry) do
      fetch_client_and_page_settings
    end

    # clear memcache if r is error?
    Memcache.delete(memcache_template_key) unless r.success?

    return r
  end

  # Fetch client and page settings
  #
  # * Author: Pankaj
  # * Date: 16/08/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_client_and_page_settings
    r = fetch_client_settings
    return r unless r.success?

    r = fetch_page_settings
    return r unless r.success?

    success_with_data(success_response_data)
  end

  # Fetch clients settings data
  #
  # * Author: Pankaj
  # * Date: 16/08/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_client_setting_data
    if @entity_group_id.to_i > 0
      fetch_client_and_page_settings
    else
      fetch_published_client_setting_data_from_memcache
    end
  end

  # Fetch clients Sale setting data
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_client_settings
    r = ClientManagement::GetClientSetting.new(client_id: @client_id).perform
    return r unless r.success?

    @client_setting = r.data
    success
  end

  # Fetch clients page setting data
  #
  # * Author: Aman
  # * Date: 08/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_page_settings
    return success if @entity_type.blank?
    r = page_setting_class.new(client_id: @client_id, entity_group_id: @entity_group_id).perform
    return r unless r.success?

    @page_setting = r.data
    success
  end

  def page_setting_class
    case @entity_type
      when GlobalConstant::EntityGroupDraft.theme_entity_type
        ClientManagement::PageSetting::Login
      when GlobalConstant::EntityGroupDraft.login_entity_type
        ClientManagement::PageSetting::Login
      when GlobalConstant::EntityGroupDraft.registration_entity_type
        ClientManagement::PageSetting::SignUp
      when GlobalConstant::EntityGroupDraft.reset_password_entity_type
        ClientManagement::PageSetting::ResetPassword
      when GlobalConstant::EntityGroupDraft.change_password_entity_type
        ClientManagement::PageSetting::ChangePassword
      when GlobalConstant::EntityGroupDraft.token_sale_blocked_region_entity_type
        ClientManagement::PageSetting::TokenSaleBlockedRegion
      when GlobalConstant::EntityGroupDraft.verification_entity_type
        ClientManagement::PageSetting::Verification
      when GlobalConstant::EntityGroupDraft.kyc_entity_type
        ClientManagement::PageSetting::Kyc
      when GlobalConstant::EntityGroupDraft.dashboard_entity_type
        ClientManagement::PageSetting::Dashboard
      else
        fail 'invalid template type'
    end
  end

  # User detail
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Hash] hash of client settings data
  #
  def success_response_data
    {
        client_setting: @client_setting,
        page_setting: @page_setting
    }
  end

  # self method to flush all client setting data for all templates of a client
  #
  # * Author: Aman
  # * Date: 15/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - client id
  #
  # @return [Hash] hash of client settings data
  #
  def self.flush_client_Settings_cache(client_id)
    memcache_key_object = MemcacheKey.new('client.client_setting_detail')
    EntityGroupDraft.entity_types.each_key do |entity_type|
      memcache_template_key = memcache_key_object.key_template % {client_id: client_id, entity_type: entity_type}
      Memcache.delete(memcache_template_key)
    end
  end

end