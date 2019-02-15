class AdminSessionSetting < EstablishSimpleTokenAdminDbConnection

  include ActivityChangeObserver

  enum status: {
      GlobalConstant::AdminSessionSetting.active_status => 1,
      GlobalConstant::AdminSessionSetting.deleted_status => 2
  }

  scope :is_active, -> {where(status: GlobalConstant::AdminSessionSetting.active_status)}

  scope :is_super_admin, -> {where("(admin_types & ?) = ?",
                                   AdminSessionSetting.admin_types_config[GlobalConstant::Admin.super_admin_role],
                                   AdminSessionSetting.admin_types_config[GlobalConstant::Admin.super_admin_role])}

  scope :is_normal_admin, -> {where("(admin_types & ?) = ?",
                                   AdminSessionSetting.admin_types_config[GlobalConstant::Admin.normal_admin_role],
                                   AdminSessionSetting.admin_types_config[GlobalConstant::Admin.normal_admin_role])}

  after_commit :memcache_flush

  # Sets the default session settings for the client
  #
  # * Author: Tejas
  # * Date: 04/02/2019
  # * Reviewed By:
  #
  #
  def default_setting!
    self.session_inactivity_timeout = GlobalConstant::AdminSessionSetting.default_session_inactivity_timeout
    self.mfa_frequency = GlobalConstant::AdminSessionSetting.default_mfa_frequency
  end

  # Array of admin types for client
  #
  # * Author: Tejas
  # * Date: 04/02/2019
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of admin types bits set for client
  #
  def admin_types_array
    @admin_types_array = AdminSessionSetting.get_bits_set_for_admin_types(admin_types)
  end

  # kyc fields config
  #
  # * Author: Tejas
  # * Date: 04/02/2019
  # * Reviewed By:
  #
  def self.admin_types_config
    @admin_types_config ||= begin
      at_c = {}
      Admin.roles.each do |admin_role, value|
        at_c[admin_role.to_s] = 2 ** (value - 1)
      end
      at_c
    end
  end

  # Bitwise columns config
  #
  # * Author: Tejas
  # * Date: 04/02/2019
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        admin_types: admin_types_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 16/10/2018
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_active_memcache_key_object
    MemcacheKey.new('admin.admin_session_settings_active')
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
    memcache_key_object = AdminSessionSetting.get_active_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      AdminSessionSetting.is_active.where(client_id: client_id).order('id DESC').all.to_a
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Tejas
  # * Date: 25/10/2018
  # * Reviewed By:
  #
  def memcache_flush
    admin_session_setting_memcache_key = AdminSessionSetting.get_active_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(admin_session_setting_memcache_key)
  end

end
