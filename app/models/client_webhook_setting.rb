class ClientWebhookSetting < EstablishSimpleTokenClientDbConnection

  include ActivityChangeObserver

  enum status: {
      GlobalConstant::ClientWebhookSetting.active_status => 1,
      GlobalConstant::ClientWebhookSetting.inactive_status => 2,
      GlobalConstant::ClientWebhookSetting.deleted_status => 3
  }

  scope :is_active, -> {where(status: GlobalConstant::ClientWebhookSetting.active_status)}
  scope :last_processed, -> {order(last_processed_at: :asc).first}

  after_commit :memcache_flush

  # Array of event result types
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of event result types bits set for Client Webhook Settings
  #
  def event_result_types_array
    @event_result_types_array = ClientWebhookSetting.get_bits_set_for_event_result_types(event_result_types)
  end

  # event result types config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.event_result_types_config
    @e_r_types_config ||= {
        GlobalConstant::Event.user_result_type => 1,
        GlobalConstant::Event.user_kyc_result_type => 2
    }
  end

  # Array of event sources
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of event sources bits set for Client Webhook Settings
  #
  def event_sources_array
    @event_sources_array = ClientWebhookSetting.get_bits_set_for_event_sources(event_sources)
  end

  # event sources config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.event_sources_config
    @e_sources_config ||= {
        GlobalConstant::Event.web_source => 1,
        GlobalConstant::Event.api_source => 2,
        GlobalConstant::Event.kyc_system_source => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 12/10/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        event_result_types: event_result_types_config,
        event_sources: event_sources_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern
  include AttributeParserConcern

  # Get Key Object
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_webhook_setting')
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 16/10/2018
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_active_memcache_key_object
    MemcacheKey.new('client.client_webhook_setting_active')
  end

  # Get decrypt_secret_key Object
  #
  # * Author: Aman
  # * Date: 16/10/2018
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_decrypted_secret_key_memcache_key_object
    MemcacheKey.new('client.webhook_decrypt_secret_key')
  end

  # Get/Set Memcache data for ClientWebhookSetting
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By
  #
  # @param [Integer] client_id - client_id
  #
  # @return [AR] ClientWebhookSetting object
  #
  def self.get_from_memcache(id)
    memcache_key_object = ClientWebhookSetting.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: id}, memcache_key_object.expiry) do
      ClientWebhookSetting.where(id: id).first
    end
  end

  # Get/Set Memcache data for ClientWebhookSetting
  #
  # * Author: Aman
  # * Date: 15/10/2018
  # * Reviewed By
  #
  # @param [Integer] client_id - client_id
  #
  # @return [AR] ClientWebhookSetting object
  #
  def self.get_active_from_memcache(client_id)
    memcache_key_object = ClientWebhookSetting.get_active_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientWebhookSetting.is_active.where(client_id: client_id).order('id DESC').all
    end
  end

  # Decrypted secret key
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By: aman
  #
  #
  def decrypted_secret_key
    @decrypted_secret_key ||= get_decrypted_secret_key_from_memcache.data[:plaintext]
  end

  # Set Decrypted secret key
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By: aman
  #
  #
  def set_decrypted_secret_key(val)
    @decrypted_secret_key = val
  end

  # Get/Set Memcache decrypted secret key for ClientWebhookSetting
  #
  # * Author: Aman
  # * Date: 15/10/2018
  # * Reviewed By
  #
  # @param [Integer] client_id - client_id
  #
  # @return [Result::Base] return result base with decrypted secret key
  #
  def get_decrypted_secret_key_from_memcache
    memcache_key_object = ClientWebhookSetting.get_decrypted_secret_key_memcache_key_object

    memcache_key_template = memcache_key_object.key_template % {id: self.id, client_id: self.client_id}
    encryption_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.memcache_encryption_key)

    # returns encrypted by local cipher using memcache key
    r = Memcache.get_set_memcached(memcache_key_template, memcache_key_object.expiry) do
      r = get_decrypted_secret_key
      return r unless r.success?

      r = encryption_obj.encrypt(r.data[:plaintext])
      r
    end

    unless r.success?
      Memcache.delete(memcache_key_template)
      return r
    end

    encryption_obj.decrypt(r.data[:ciphertext_blob])
  end

  # Set the extra needed data for hashed response
  #
  # * Author: Aman
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def extra_fields_to_set
    {
        decrypted_secret_key: decrypted_secret_key
    }
  end

  private

  # decrypt secret key
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By:
  #
  def get_decrypted_secret_key
    client = Client.get_from_memcache(self.client_id)
    r = Aws::Kms.new('saas', 'saas').decrypt(client.api_salt)
    return r unless r.success?

    api_salt_d = r.data[:plaintext]

    LocalCipher.new(api_salt_d).decrypt(self.secret_key)
  end

  # Columns to be removed from the hashed response
  #
  # * Author: Aman
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def self.restricted_fields
    [:secret_key]
  end

  # Flush Memcache
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def memcache_flush
    memcache_key = ClientWebhookSetting.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(memcache_key)

    memcache_key = ClientWebhookSetting.get_active_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(memcache_key)

    if self.previous_changes["secret_key"].present?
      memcache_key = ClientWebhookSetting.get_decrypted_secret_key_memcache_key_object.key_template % {id: self.id, client_id: self.client_id}
      Memcache.delete(memcache_key)
    end

  end


end
