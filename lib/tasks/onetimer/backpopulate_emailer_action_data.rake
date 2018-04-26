namespace :onetimer do

  task :backpopulate_emailer_action_data => :environment do
    UserKycDetail.where(admin_action_types: [2, 3, 4]).update_all(admin_action_types: 2)

    data_mismatch_map = {
        'First name' => 'first_name',
        'Last name' => 'last_name',
        'Birthdate' => 'birthdate',
        'Nationality' => 'nationality',
        'Document id number' => 'document_id_number'
    }

    kms_login_client = Aws::Kms.new('entity_association', 'general_access')
    r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
    activity_log_decyption_salt = r.data[:plaintext]


    UserActivityLog.where(action: 6).find_in_batches(batch_size: 100) do |uals|
      uals.each do |ual|
        ual.action = GlobalConstant::UserActivityLog.kyc_issue_email_sent_action

        if ual.e_data.present?
          data_hash = LocalCipher.new(activity_log_decyption_salt).decrypt(ual.e_data).data[:plaintext]
          updated_data = {}
          updated_data[GlobalConstant::UserKycDetail.data_mismatch_admin_action_type] = []

          data_hash[:error_fields].each do |err|
            new_val = data_mismatch_map[err]
            throw "INVALID data_mismatch val data_hash-#{data_hash} u_activity_log_id: #{ual.id}" if new_val.blank?
            updated_data[GlobalConstant::UserKycDetail.data_mismatch_admin_action_type] << new_val
          end

          updated_data.deep_symbolize_keys

          r = LocalCipher.new(activity_log_decyption_salt).encrypt(updated_data)
          throw 'FAILED TO DECRYPT' unless r.success?
          ual.e_data = r.data[:ciphertext_blob]
        end
        ual.save!
      end
    end

    UserActivityLog.where(action: [7, 8, 9]).find_in_batches(batch_size: 100) do |uals|
      uals.each do |ual|
        ual.action = GlobalConstant::UserActivityLog.kyc_issue_email_sent_action
        throw "FOUND E_DATA for image issue actions u_activity_log_id: #{ual.id}" if ual.e_data.present?

        updated_data = {}
        str = case ual.read_attribute_before_type_cast('action')
                when 7
                  "document_id_issue"
                when 8
                  "selfie_issue"
                when 9
                  "residency_proof_issue"
                else
                  throw "unidentified action #{ual.action}"
              end

        updated_data[GlobalConstant::UserKycDetail.document_issue_admin_action_type] = [str]
        updated_data.deep_symbolize_keys

        r = LocalCipher.new(activity_log_decyption_salt).encrypt(updated_data)
        throw 'FAILED TO DECRYPT' unless r.success?
        ual.e_data = r.data[:ciphertext_blob]
        ual.save!
      end
    end

  end

end
