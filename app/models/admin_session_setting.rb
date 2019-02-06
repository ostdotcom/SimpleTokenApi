class AdminSessionSetting < EstablishSimpleTokenAdminDbConnection

  include ActivityChangeObserver

  enum status: {
      GlobalConstant::AdminSessionSetting.active_status => 1,
      GlobalConstant::AdminSessionSetting.deleted_status => 2
  }

  scope :is_active, -> {where(status: GlobalConstant::AdminSessionSetting.active_status)}


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
end
