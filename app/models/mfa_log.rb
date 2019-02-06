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
  def get_mfa_session_value
    "#{self.id}:#{self.token}:#{self.last_mfa_time}"
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
    MfaLog.get_mfa_session_key(self.admin_id, self.ip_address, self.browser_user_agent)
  end

  # Get MFA Session Key
  #
  # * Author: Tejas
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  # @return [String] MFA Session value
  #
  def self.get_mfa_session_key(admin_id, ip_address, browser_user_agent)
    "#{admin_id}##{ip_address}##{browser_user_agent}"
  end


end
