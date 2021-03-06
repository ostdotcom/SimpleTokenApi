namespace :onetimer do

  # rake RAILS_ENV=development onetimer:insert_general_salt_key_row_in_table salt_type=user_activity_logging
  task :insert_general_salt_key_row_in_table => :environment do
    @salt_type = ENV['salt_type']

    # create a salt in general salt table
    #
    # * Author: Aman
    # * Date: 02/11/2017
    # * Reviewed By: Sunil
    #
    # create a row for salt.Onetimer Should not be created twice for a salt
    #
    def insert_salt_in_general_salt
      fail 'Salt type not present' if @salt_type.blank?
      kms_login_client = Aws::Kms.new('entity_association', 'general_access')
      r = kms_login_client.generate_data_key
      fail 'unable to generate salt keys' unless r.success?

      e_salt = r.data[:ciphertext_blob]
      GeneralSalt.create!(salt_type: @salt_type, salt: e_salt)
    end

    insert_salt_in_general_salt
  end

end