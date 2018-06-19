namespace :onetimer do

  # Update birthdate in UserExtendedDetails
  #
  # * Author: Aniket
  # * Date: 18/06/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:backpopulate_birthdate
  #
  task :backpopulate_birthdate => :environment do

    UserExtendedDetail.find_in_batches(batch_size: 100) do |ueds|

      ueds.each do |ued|
        @local_cipher = nil

        kyc_salt_d = decrypt_kyc_salt(ued.kyc_salt)
        @local_cipher = LocalCipher.new(kyc_salt_d)

        birth_date = birthdate_d(ued.birthdate)
        puts "birthdate after: #{birth_date}"
        encrypted_birthdate = encrypt_birthdate(birth_date)
        ued.birthdate = encrypted_birthdate
        ued.save!(touch: false)
      end
    end

  end

  def decrypt_kyc_salt(kyc_salt)
    r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt)
    fail "unable to decrypt kyc salt" unless r.success?

    r.data[:plaintext]
  end

  def birthdate_d(birthdate)
    r = @local_cipher.decrypt(birthdate)
    fail "unable to decrypt birthdate" unless r.success?

    birthdate = r.data[:plaintext]
    puts "birthdate before: #{birthdate}"
    Time.zone.strptime(birthdate, "%Y-%m-%d").strftime("%Y-%m-%d")
  end

  def encrypt_birthdate(birthdate)
    r = @local_cipher.encrypt(birthdate)
    fail "unable to encrypt birthdate" unless r.success?
    r.data[:ciphertext_blob]
  end

end