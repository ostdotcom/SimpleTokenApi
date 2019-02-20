class AdminSecret < EstablishSimpleTokenAdminDbConnection

  after_commit :memcache_flush

  enum status: {
      GlobalConstant::AdminSessionSetting.active_status => 1,
      GlobalConstant::AdminSessionSetting.deleted_status => 2
  }

  scope :is_active, -> {where(status: GlobalConstant::AdminSecret.active_status)}

  # Login Salt Decrypted
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def login_salt_decrypted
    r = Aws::Kms.new('login', 'admin').decrypt(self.login_salt)
    return throw 'error as_lse_2' unless r.success?

    r.data[:plaintext]
  end

  # Ga Secret Decrypted
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def ga_secret_decrypted
    decryptor_obj = LocalCipher.new(self.login_salt_decrypted)

    resp = decryptor_obj.decrypt(self.ga_secret)
    return resp unless resp.success?

    resp
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_active_memcache_key_object
    MemcacheKey.new('admin.admin_secret_details_active')
  end

  # Get/Set Memcache data for Active Admin Secret
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @param [Integer] admin_secret_id - admin secret id
  #
  # @return [AR] AdminSecret object
  #
  def self.get_active_from_memcache(admin_secret_id)
    memcache_key_object = AdminSecret.get_active_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: admin_secret_id}, memcache_key_object.expiry) do
      AdminSecret.is_active.where(id: admin_secret_id).first
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def memcache_flush
    admin_secret_details_memcache_key = AdminSecret.get_active_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(admin_secret_details_memcache_key)
  end
end
