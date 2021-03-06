class UserActivityLog

  module Methods
    extend ActiveSupport::Concern
    included do

      enum log_type: {
          GlobalConstant::UserActivityLog.admin_log_type => 1,
          GlobalConstant::UserActivityLog.developer_log_type => 2
      }, _suffix: true

      enum action: {
          GlobalConstant::UserActivityLog.register_action => 1,
          GlobalConstant::UserActivityLog.double_opt_in_action => 2,
          GlobalConstant::UserActivityLog.update_kyc_action => 3,
          GlobalConstant::UserActivityLog.kyc_denied_action => 4,
          GlobalConstant::UserActivityLog.kyc_qualified_action => 5,

          #todo: WEBCODECHANGE
          # GlobalConstant::UserActivityLog.data_mismatch_email_sent_action => 6,
          # GlobalConstant::UserActivityLog.document_id_issue_email_sent_action => 7,
          # GlobalConstant::UserActivityLog.selfie_issue_email_sent_action => 8,
          # GlobalConstant::UserActivityLog.residency_issue_email_sent_action => 9,

          GlobalConstant::UserActivityLog.login_action => 10,
          GlobalConstant::UserActivityLog.kyc_whitelist_attention_needed => 11,
          GlobalConstant::UserActivityLog.kyc_whitelist_processor_error => 12,
          GlobalConstant::UserActivityLog.aml_api_error => 13,
          GlobalConstant::UserActivityLog.update_ethereum_address => 14,
          GlobalConstant::UserActivityLog.open_case => 15,
          GlobalConstant::UserActivityLog.phase_changed_to_early_access => 16,
          GlobalConstant::UserActivityLog.kyc_issue_email_sent_action => 17
      }, _suffix: true

      # decrypt data if present
      #
      # * Author: Aman
      # * Date: 02/11/2017
      # * Reviewed By: Sunil
      #
      # Returns[Hash] Data decrypted with salt. Error Handling should be done by individual callers
      #
      def decrypted_extra_data
        return {} if e_data.blank?
        kms_login_client = Aws::Kms.new('entity_association', 'general_access')
        r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
        r = LocalCipher.new(r.data[:plaintext]).decrypt(e_data)
        r.data[:plaintext]
      end

    end

    module ClassMethods

    end

  end

end