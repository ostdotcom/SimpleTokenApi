namespace :onetimer do

  # rake RAILS_ENV=development onetimer:repopulate_user_activity_log_table
  task :repopulate_user_activity_log_table => :environment do
    get_salt_for_user_activity_logging
    encrypt_data_in_db
  end

  # get decrypted salt for user activity logging
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By:
  #
  # Sets @d_salt
  #
  def get_salt_for_user_activity_logging
    kms_login_client = Aws::Kms.new('entity_association', 'entity_association')
    r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
    @d_salt = r.data[:plaintext]
  end

  # Encrypt data in db
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By:
  #
  def encrypt_data_in_db
    # UserActivityLog.where(id: 17).all.each do |obj|
    UserActivityLog.all.each do |obj|
      next if obj.data.blank?
      puts "Current Id-#{obj.id}"
      obj.e_data = encrypted_extra_data(obj.data)
      obj.save!
    end
  end

  # encrypt data if present
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By:
  #
  # Returns[Result::Base] Data Encrypted with salt if present.
  #
  def encrypted_extra_data(data_hash)
    return nil if data_hash.blank?

    r = LocalCipher.new(@d_salt).encrypt(data_hash)
    fail "Unable to encrypt for data--#{data_hash}\n\n--salt#{@d_salt}" unless r.success?

    r.data[:ciphertext_blob]
  end


end