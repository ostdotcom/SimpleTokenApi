namespace :onetimer do

  # rake RAILS_ENV=development onetimer:repopulate_user_activity_log_table
  task :repopulate_user_activity_log_table => :environment do

    # get decrypted salt for user activity logging
    #
    # * Author: Aman
    # * Date: 02/11/2017
    # * Reviewed By: Sunil
    #
    # Sets @d_salt
    #
    def get_salt_for_user_activity_logging


    end

    # Encrypt data in db
    #
    # * Author: Aman
    # * Date: 02/11/2017
    # * Reviewed By: Sunil
    #
    def encrypt_data_in_db

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
          # browser_user_agent

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

    # encrypt data if present
    #
    # * Author: Aman
    # * Date: 02/11/2017
    # * Reviewed By: Sunil
    #
    # Returns[Result::Base] Data Encrypted with salt if present.
    #
    def encrypted_extra_data(data_hash)
      return nil if data_hash.blank?

      r = LocalCipher.new(@d_salt).encrypt(data_hash)
      fail "Unable to encrypt for data--#{data_hash}\n\n--salt#{@d_salt}" unless r.success?

      r.data[:ciphertext_blob]
    end

    get_salt_for_user_activity_logging
    encrypt_data_in_db

  end

end