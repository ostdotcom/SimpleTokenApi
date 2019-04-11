module Crons

  class DeleteMfaLogs

    # initialize
    #
    # * Author: Aman
    # * Date: 13/04/2019
    # * Reviewed By:
    #
    # @return [Crons::DeleteMfaLogs]
    #
    def initialize(params={})
    end

    # perform
    #
    # * Author: Aman
    # * Date: 13/04/2019
    # * Reviewed By:
    #
    # Delete MFA Logs after 15 days
    #
    def perform

      MfaLog.where(status: GlobalConstant::MfaLog.deleted_status).delete_all

      last_mfa_time_for_deletion = Time.now.to_i - GlobalConstant::AdminSessionSetting.max_mfa_frequency_value.days.to_i
      MfaLog.where(status: GlobalConstant::MfaLog.active_status).
          where('last_mfa_time < ?', last_mfa_time_for_deletion).delete_all
    end

  end

end