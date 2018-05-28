namespace :onetimer do

  # rake RAILS_ENV=development onetimer:populate_salt_for_eu_region

  task :populate_salt_for_eu_region => :environment do

    def start_backpopulate
      populate_user_kyc_details
      populate_client
      populate_admin_secret
      populate_user_secret
      populate_user_activity_logging_in_general_salt
    end


    def populate_user_kyc_details
      puts "started populating eu kyc salt for user_kyc_details"
      credentials = GlobalConstant::Aws::Common.get_credentials_for('admin')
      kms_client = get_kms_client(credentials)
      kms_key_id = ENV['STA_EU_KYC_KMS_ID']
      i = 0
      UserExtendedDetail.where(eu_kyc_salt: nil).find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|

          r = Aws::Kms.new('kyc', 'admin').decrypt(row_obj.kyc_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          salt_d = r.data[:plaintext]

          r = encrypt(kms_client, kms_key_id, salt_d)
          fail "unable to encrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          row_obj.eu_kyc_salt = r.data[:ciphertext_blob]
          row_obj.save!(touch: false)
        end
      end
    end

    def populate_client
      puts "started populating eu api_salt for client"
      credentials = GlobalConstant::Aws::Common.get_credentials_for('saas')
      kms_client = get_kms_client(credentials)
      kms_key_id = ENV['STA_EU_SAAS_KMS_ID']
      i = 0
      Client.where(eu_api_salt: nil).find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|

          r = Aws::Kms.new('saas', 'saas').decrypt(row_obj.api_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          salt_d = r.data[:plaintext]

          r = encrypt(kms_client, kms_key_id, salt_d)
          fail "unable to encrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          row_obj.eu_api_salt = r.data[:ciphertext_blob]
          row_obj.save!(touch: false)
        end
      end
    end

    def populate_admin_secret
      puts "started populating eu login_salt for admin_secret"
      credentials = GlobalConstant::Aws::Common.get_credentials_for('admin')
      kms_client = get_kms_client(credentials)
      kms_key_id = ENV['STA_EU_LOGIN_KMS_ID']
      i = 0
      AdminSecret.where(eu_login_salt: nil).find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|

          r = Aws::Kms.new('login', 'admin').decrypt(row_obj.login_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          salt_d = r.data[:plaintext]

          r = encrypt(kms_client, kms_key_id, salt_d)
          fail "unable to encrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          row_obj.eu_login_salt = r.data[:ciphertext_blob]
          row_obj.save!(touch: false)
        end
      end
    end

    def populate_user_secret
      puts "started populating eu login_salt for user_secret"
      credentials = GlobalConstant::Aws::Common.get_credentials_for('user')
      kms_client = get_kms_client(credentials)
      kms_key_id = ENV['STA_EU_LOGIN_KMS_ID']
      i = 0
      UserSecret.where(eu_login_salt: nil).find_in_batches(batch_size: 500) do |rows|
        puts "Iteration #{i}"
        i += 1
        rows.each do |row_obj|

          r = Aws::Kms.new('login', 'user').decrypt(row_obj.login_salt)
          fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          salt_d = r.data[:plaintext]

          r = encrypt(kms_client, kms_key_id, salt_d)
          fail "unable to encrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

          row_obj.eu_login_salt = r.data[:ciphertext_blob]
          row_obj.save!(touch: false)
        end
      end
    end

    def populate_user_activity_logging_in_general_salt
      puts "started populating eu user_activity_logging_salt for user_activity_logging_salt"
      credentials = GlobalConstant::Aws::Common.get_credentials_for('general_access')
      kms_client = get_kms_client(credentials)
      kms_key_id = ENV['STA_EU_ENTITY_ASSOC_ID']

      row_obj = GeneralSalt.user_activity_logging_salt_type.first
      return if row_obj.eu_salt.present?

      r = Aws::Kms.new('entity_association', 'general_access').decrypt(row_obj.salt)
      fail "unable to decrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

      salt_d = r.data[:plaintext]

      r = encrypt(kms_client, kms_key_id, salt_d)
      fail "unable to encrypt #{row_obj.class} id-#{row_obj.id}" unless r.success?

      row_obj.eu_salt = r.data[:ciphertext_blob]
      row_obj.save!(touch: false)
    end

    def get_kms_client(credentials)
      Aws::KMS::Client.new(
          access_key_id: credentials['access_key'],
          secret_access_key: credentials['secret_key'],
          region: 'eu-west-1'
      )
    end

    def encrypt(client, key_id, plaintext)
      begin

        e_resp = client.encrypt({
                                    plaintext: plaintext,
                                    key_id: key_id
                                }).to_h

        ciphertext_blob = e_resp[:ciphertext_blob]

        return success_with_data(
            ciphertext_blob: ciphertext_blob
        )

      rescue => e
        return exception_with_data(
            e,
            'rake_psfer_1',
            'exception in encrypt: ' + e.message,
            'Something went wrong. Please try after sometime.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
    end

    start_backpopulate

  end

end
