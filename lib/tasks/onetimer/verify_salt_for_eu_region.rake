namespace :onetimer do

  # rake RAILS_ENV=development onetimer:verify_salt_for_eu_region

  task :verify_salt_for_eu_region => :environment do

    def start_verify
      verify_user_kyc_details
      verify_client
      verify_admin_secret
      verify_user_secret
      verify_user_activity_logging_in_general_salt
    end


    def verify_user_kyc_details
      puts "started verifying kyc salt for user_kyc_details"
      i = 0
      UserExtendedDetail.find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|
          r = Aws::Kms.new('kyc', 'admin').decrypt(row_obj.kyc_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?
          salt_d = r.data[:plaintext]
          local_cipher_obj = LocalCipher.new(salt_d)

          data_to_decrypt = [
              :birthdate,
              :street_address,
              :city,
              :state,
              :country,
              :postal_code,
              :ethereum_address,
              :estimated_participation_amount,
              :document_id_number,
              :nationality,
              :document_id_file_path,
              :selfie_file_path,
              :residence_proof_file_path,
              :investor_proof_files_path
          ]

          data_to_decrypt.each do |key|
            value = row_obj[key]
            next if value.blank?
            r = local_cipher_obj.decrypt(value)
            fail "unable to decrypt #{row_obj.class} :: id-#{row_obj.id} :: key-#{key}" unless r.success?
          end

        end
      end
    end

    def verify_client
      puts "started verifying api_salt for client"
      i = 0
      Client.find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|
          r = Aws::Kms.new('saas', 'saas').decrypt(row_obj.api_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?
          api_salt_d = r.data[:plaintext]
          local_cipher_obj = LocalCipher.new(api_salt_d)

          obj = ClientPepoCampaignDetail.where(client_id: row_obj.id).first
          if obj.present?
            r = local_cipher_obj.decrypt(obj.api_secret)
            fail "unable to decrypt ClientPepoCampaignDetail :: id-#{obj.id}" unless r.success?
          end


          obj = ClientCynopsisDetail.where(client_id: row_obj.id).first
          if obj.present?
            r = local_cipher_obj.decrypt(obj.token)
            fail "unable to decrypt ClientCynopsisDetail :: id-#{obj.id}" unless r.success?
          end
        end
      end
    end

    def verify_user_activity_logging_in_general_salt
      puts "started verifying user_activity_logging_salt for user_activity_logging_salt"

      log_salt = GeneralSalt.get_user_activity_logging_salt_type
      r = Aws::Kms.new('entity_association', 'general_access').decrypt(log_salt)
      fail "unable to decrypt user_activity_logging_in_general_salt" unless r.success?
      activity_log_decyption_salt = r.data[:plaintext]
      decryptor_obj = LocalCipher.new(activity_log_decyption_salt)
      i = 0

      UserActivityLog.find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|
          next if row_obj.e_data.blank?
          r = decryptor_obj.decrypt(row_obj.e_data)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?
        end
      end
    end

    def verify_admin_secret
      puts "started verifying login_salt for admin_secret"

      i = 0
      AdminSecret.find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|
          r = Aws::Kms.new('login', 'admin').decrypt(row_obj.login_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?
        end
      end
    end

    def verify_user_secret
      puts "started verifying login_salt for user_secret"
      i = 0
      UserSecret.find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|
          r = Aws::Kms.new('login', 'user').decrypt(row_obj.login_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?
        end
      end
    end

    start_verify

  end

end
