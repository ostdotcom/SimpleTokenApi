namespace :onetimer do

  # rake RAILS_ENV=development onetimer:insert_general_salt_key_row_in_table salt_type=user_activity_logging
  task :insert_general_salt_key_row_in_table => :environment do
    @salt_type = ENV['salt_type']
    insert_salt_for_user_activity_logging
  end

  # create a salt for user activity logging
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By:
  #
  # create a row for salt.Onetimer Should not be created twice for a salt
  #
  def insert_salt_for_user_activity_logging
    fail 'Salt type not present' if @salt_type.blank?
    kms_login_client = Aws::Kms.new('entity_association', 'entity_association')
    r = kms_login_client.generate_data_key
    fail 'unable to generate salt keys' unless r.success?

    e_salt = r.data[:ciphertext_blob]
    GeneralSalt.create!(salt_type: @salt_type, salt: e_salt)
  end
end