namespace :onetimer do

  # rake RAILS_ENV=development onetimer:remove_ip_address_logs
  task :remove_ip_address_logs => :environment do

    # remove ip address from logs
    #
    # * Author: Aman
    # * Date: 04/04/2019
    # * Reviewed By:
    #
    def remove_ip_address_logs

      kms_login_client = Aws::Kms.new('entity_association', 'general_access')
      r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
      lc = LocalCipher.new(r.data[:plaintext])

      UserActivityLog.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier).
          where(action: [GlobalConstant::UserActivityLog.login_action, GlobalConstant::UserActivityLog.register_action]).
          find_in_batches(batch_size: 100) do |batched_records|

        batched_records.each do |obj|
          puts "Current Id-#{obj.id}"
          next if obj.e_data.blank?


          r = lc.decrypt(obj.e_data)
          fail "Unable to decrypt for data--#{data_hash}\n\n" unless r.success?

          extra_data = r.data[:plaintext]
          extra_data.delete(:ip_address)
          extra_data.delete("ip_address")

          e_extra_data = nil
          if extra_data.present?
            r = lc.encrypt(extra_data)
            fail "Unable to encrypt for data--#{extra_data}\n\n" unless r.success?
            e_extra_data = r.data[:ciphertext_blob]
          end

          obj.e_data = e_extra_data
          obj.save!
        end
      end

    end
    remove_ip_address_logs

  end

end