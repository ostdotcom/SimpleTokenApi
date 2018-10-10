class AdminSecret < EstablishSimpleTokenAdminDbConnection

  after_commit :memcache_flush

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
  def self.get_memcache_key_object
    MemcacheKey.new('admin.admin_secret_details')
  end

  # Get/Set Memcache data for User
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @param [Integer] user_id - user id
  #
  # @return [AR] User object
  #
  def self.get_from_memcache(admin_secret_id)
    memcache_key_object = AdminSecret.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: admin_secret_id}, memcache_key_object.expiry) do
      AdminSecret.where(id: admin_secret_id).first
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
    admin_secret_details_memcache_key = AdminSecret.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(admin_secret_details_memcache_key)
  end
end
