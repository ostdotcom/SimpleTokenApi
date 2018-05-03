class ClientTemplate < EstablishSimpleTokenClientDbConnection

  serialize :data, Hash

  enum template_type: {
      GlobalConstant::ClientTemplate.common_template_type => 1,
      GlobalConstant::ClientTemplate.login_template_type => 2,
      GlobalConstant::ClientTemplate.sign_up_template_type => 3,
      GlobalConstant::ClientTemplate.reset_password_template_type => 4,
      GlobalConstant::ClientTemplate.change_password_template_type => 5,
      GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type => 6,
      GlobalConstant::ClientTemplate.kyc_template_type => 7,
      GlobalConstant::ClientTemplate.dashboard_template_type => 8,
      GlobalConstant::ClientTemplate.verification_template_type => 9

  }

  after_commit :memcache_flush

  # Get Key Object by client id and template type
  #
  # * Author: Aman
  # * Date: 09/02/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_by_client_id_and_template_type_key_object
    MemcacheKey.new('client.client_template_type_details')
  end

  # Get/Set Memcache data for clients host details by client id
  #
  # * Author: Aman
  # * Date: 09/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  # @param [String] template_type - template type name
  #
  # @return [AR] ClientTemplate object
  #
  def self.get_from_memcache_by_client_id_and_template_type(client_id, template_type)
    memcache_key_object = ClientTemplate.get_memcache_by_client_id_and_template_type_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id, template_type: template_type}, memcache_key_object.expiry) do
      ClientTemplate.where(client_id: client_id, template_type: template_type).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 09/02/2018
  # * Reviewed By:
  #
  def memcache_flush
    memcache_key = ClientTemplate.get_memcache_by_client_id_and_template_type_key_object.key_template % {client_id: self.client_id, template_type: self.template_type}
    Memcache.delete(memcache_key)

    if self.template_type == GlobalConstant::ClientTemplate.common_template_type
      ClientSetting.flush_memcache_key_for_template_types_of_client(self.client_id)
    else
      ClientSetting.flush_memcache_key_for_template_types_of_client(self.client_id, [self.template_type])
    end
  end

end