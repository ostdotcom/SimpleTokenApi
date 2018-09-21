namespace :onetimer do


  # params = {
  #     "update_country_hash" => {
  #         "INIDA" => "INDIAN",
  #         "WESTERN SAHARAN" => "WESTERN SAHARA"
  #     },
  #
  #     "update_country_hash" => {
  #         "INIDA" => "INDIAN",
  #         "WESTERN SAHARAN" => "WESTERN SAHARA"
  #     }
  # }

  # params = params.to_json
  # rake RAILS_ENV=development onetimer:arthemis_update params="{\"update_country_hash\":{\"IRAN1\":\"IRAN\",\"SRI LANKA1\":\"SRI LANKA\",\"INDIA\":\"INDIA1\"},\"update_nationality_hash\":{\"CHINESE1\":\"CHINESE\",\"SYRIAN1\":\"SYRIAN\",\"INDIAN\":\"INDIAN1\"}}"


  # Arthemis Update
  #
  # * Author: Tejas
  # * Date: 27/07/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:arthemis_update
  #
  task :arthemis_update => :environment do

    # params = JSON.parse(ENV['params'])

    params = {
        "update_country_hash" => {
            "IRAN1" => "IRAN",
            "SRI LANKA1" => "SRI LANKA",
            "INDIA" => "INDIA1"
        },
        "update_nationality_hash" => {
            "CHINESE1" => "CHINESE",
            "SYRIAN1" => "SYRIAN",
            "INDIAN" => "INDIAN1"
        }
    }

    update_country_hash = params["update_country_hash"]
    update_nationality_hash = params["update_nationality_hash"]

    update_country_hash.each do |old_country, new_country|
      ClientKycConfigDetail.all.each do |row|
        blacklisted_countries = row.blacklisted_countries
        if blacklisted_countries.include?(old_country)
          index = blacklisted_countries.index(old_country)
          blacklisted_countries[index] = new_country
        end
        row.blacklisted_countries = blacklisted_countries
        row.save
      end

      hashed_db_country = Md5UserExtendedDetail.get_hashed_value(old_country)
      user_extended_detail_ids = Md5UserExtendedDetail.where(country: hashed_db_country).pluck(:user_extended_detail_id)
      next if user_extended_detail_ids.blank?

      user_extended_detail_ids.each do |uedi|
        ued = UserExtendedDetail.where(id: uedi).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj ||= LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.decrypt(ued.country)
        fail 'decryption of old country failed.' unless r.success?

        decrypted_country = r.data[:plaintext]
        if decrypted_country == old_country
          r = encryptor_obj.encrypt(new_country)
          fail 'encryption of new country failed.' unless r.success?

          @encrypted_country = r.data[:ciphertext_blob]
          ued.country = @encrypted_country
          ued.save
        end
      end

      new_hashed_db_country = Md5UserExtendedDetail.get_hashed_value(new_country)
      Md5UserExtendedDetail.where(country: hashed_db_country).update(country: new_hashed_db_country)

    end

    update_nationality_hash.each do |old_nationality, new_nationality|
      ClientKycConfigDetail.all.each do |row|
        residency_proof_nationalities = row.residency_proof_nationalities
        if residency_proof_nationalities.include?(old_nationality)
          index = residency_proof_nationalities.index(old_nationality)
          residency_proof_nationalities[index] = new_nationality
        end
        row.residency_proof_nationalities = residency_proof_nationalities
        row.save
      end

      hashed_db_nationality = Md5UserExtendedDetail.get_hashed_value(old_nationality)
      user_extended_detail_ids = Md5UserExtendedDetail.where(nationality: hashed_db_nationality).pluck(:user_extended_detail_id)
      next if user_extended_detail_ids.blank?

      user_extended_detail_ids.each do |uedi|
        ued = UserExtendedDetail.where(id: uedi).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj ||= LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.decrypt(ued.nationality)
        fail 'decryption of old nationality failed.' unless r.success?

        decrypted_nationality = r.data[:plaintext]
        if decrypted_nationality == old_nationality
          r = encryptor_obj.encrypt(new_nationality)
          fail 'encryption of new nationality failed.' unless r.success?

          @encrypted_nationality = r.data[:ciphertext_blob]
          ued.nationality = @encrypted_nationality
          ued.save
        end
      end

      new_hashed_db_nationality = Md5UserExtendedDetail.get_hashed_value(new_nationality)
      Md5UserExtendedDetail.where(nationality: hashed_db_nationality).update(nationality: new_hashed_db_nationality)

    end

    puts "rake completed"

  end

end