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

  # Get MFA Session Value
  #
  # * Author: Tejas
  # * Date: 05/02/2019
  # * Reviewed By:
  #
  # @return [String] MFA Session value
  #
  def get_mfa_session_key
    "#{self.admin_id}##{self.ip_address}##{self.browser_user_agent}"
  end

end
