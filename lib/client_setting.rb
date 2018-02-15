class ClientSetting

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Aman
  # * Date: 15/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  # @param [String] template_type - template type for page
  #
  # @return [ClientSetting]
  #
  def initialize(client_id, template_type)
    @client_id = client_id
    @template_type = template_type

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
  def fetch_client_setting_data
    memcache_key_object = MemcacheKey.new('client.client_setting_detail')
    memcache_template_key = memcache_key_object.key_template % {client_id: @client_id, template_type: @template_type}

    r = Memcache.get_set_memcached(memcache_template_key, memcache_key_object.expiry) do

      r = fetch_client_settings
      return r unless r.success?

      r = fetch_page_settings
      return r unless r.success?

      success_with_data(success_response_data)
    end

    # clear memcache if r is error?
    Memcache.delete(memcache_template_key) unless r.success?

    return r
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
    return success if @template_type.blank?
    r = page_setting_class.new(client_id: @client_id).perform
    return r unless r.success?

    @page_setting = r.data
    success
  end

  def page_setting_class
    case @template_type
      when GlobalConstant::ClientTemplate.login_template_type
        ClientManagement::PageSetting::Login
      when GlobalConstant::ClientTemplate.sign_up_template_type
        ClientManagement::PageSetting::SignUp
      when GlobalConstant::ClientTemplate.reset_password_template_type
        ClientManagement::PageSetting::ResetPassword
      when GlobalConstant::ClientTemplate.change_password_template_type
        ClientManagement::PageSetting::ChangePassword
      when GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type
        ClientManagement::PageSetting::TokenSaleBlockedRegion
      when GlobalConstant::ClientTemplate.kyc_template_type
        ClientManagement::PageSetting::Kyc
      when GlobalConstant::ClientTemplate.dashboard_template_type
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

end