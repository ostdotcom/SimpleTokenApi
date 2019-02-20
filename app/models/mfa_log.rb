class MfaLog < EstablishSimpleTokenAdminDbConnection
  enum status: {
      GlobalConstant::MfaLog.active_status => 1,
      GlobalConstant::MfaLog.deleted_status => 2
  }

  # Get MFA Session Value
  #
  # * Author: Tejas
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  # @return [String] MFA Session value
  #
  def get_mfa_session_value(admin_secret_id, last_login_time)
    "#{self.id}:#{self.token}:#{self.last_mfa_time}:#{last_login_time}:#{admin_secret_id}"
  end

  # Get MFA Session key
  #
  # * Author: Tejas
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  # @return [String] MFA Session value
  #
  def session_key
    MfaLog.get_mfa_session_key(self.admin_id, self.ip_address)
  end

  # Get MFA Session Key
  #
  # * Author: Tejas
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  # @return [String] MFA Session value
  #
  def self.get_mfa_session_key(admin_id, ip_address)
    "#{admin_id}##{ip_address}"
  end


end
