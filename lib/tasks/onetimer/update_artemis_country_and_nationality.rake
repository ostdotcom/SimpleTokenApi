namespace :onetimer do


  # params = {
  #     "update_country_hash" => {
  #     "INDIA" => "INDIAN",
  #     "WESTERN SAHARAN" => "WESTERN SAHARA"
  # },
  #
  #     "update_nationality_hash" => {
  #     "AFGHANI" => "AFGHAN",
  #     "BAHRAINIAN" => "BAHRAINI",
  #     "LITHUNIAN" => "LITHUANIAN"
  # }
  # }

  # params = params.to_json
  # rake RAILS_ENV=development onetimer:update_artemis_country_and_nationality params="{\"update_country_hash\":{\"INDIAN\":\"INDIA\",\"WESTERN SAHARAN\":\"WESTERN SAHARA\"},\"update_nationality_hash\":{\"AFGHANI\":\"AFGHAN\",\"BAHRAINIAN\":\"BAHRAINI\",\"LITHUNIAN\":\"LITHUANIAN\"}}"

  # Arthemis Update
  #
  # * Author: Tejas
  # * Date: 27/07/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:update_artemis_country_and_nationality
  #
  task :update_artemis_country_and_nationality => :environment do

    params = JSON.parse(ENV['params'])

    update_country_hash = params["update_country_hash"]
    update_nationality_hash = params["update_nationality_hash"]

    puts "checking for kyc config details row to be updated"

    ClientKycConfigDetail.all.each do |row|
      blacklisted_countries = row.blacklisted_countries
      residency_proof_nationalities = row.residency_proof_nationalities

      old_countries = blacklisted_countries & update_country_hash.keys
      old_nationalities = residency_proof_nationalities & update_nationality_hash.keys

      next if old_countries.blank? && old_nationalities.blank?

      new_countries = old_countries.map {|x| update_country_hash[x]}
      new_nationalities = old_nationalities.map {|x| update_nationality_hash[x]}

      blacklisted_countries = blacklisted_countries - old_countries + new_countries
      blacklisted_countries.uniq!

      residency_proof_nationalities = residency_proof_nationalities - old_nationalities + new_nationalities
      residency_proof_nationalities.uniq!

      puts "updating ClientKycConfigDetail.id-#{row.id}"

      row.blacklisted_countries = blacklisted_countries
      row.residency_proof_nationalities = residency_proof_nationalities
      row.save!
    end


    update_country_hash.each do |old_country, new_country|

      puts "updating country-#{old_country}"

      hashed_db_country = Md5UserExtendedDetail.get_hashed_value(old_country)
      user_extended_detail_ids = Md5UserExtendedDetail.where(country: hashed_db_country).pluck(:user_extended_detail_id)
      puts "total rows to be updated-#{user_extended_detail_ids.length}"
      next if user_extended_detail_ids.blank?

      user_extended_detail_ids.each do |uedi|
        puts "updating ued row id-#{uedi}"

        ued = UserExtendedDetail.where(id: uedi).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj = LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.decrypt(ued.country)
        fail 'decryption of old country failed.' unless r.success?

        decrypted_country = r.data[:plaintext]

        fail "Country is different for id-#{uedi}" if decrypted_country.downcase != old_country.downcase

        r = encryptor_obj.encrypt(new_country)
        fail 'encryption of new country failed.' unless r.success?

        ued.country = r.data[:ciphertext_blob]
        ued.save!
      end

      new_hashed_db_country = Md5UserExtendedDetail.get_hashed_value(new_country)
      Md5UserExtendedDetail.where(user_extended_detail_id: user_extended_detail_ids, country: hashed_db_country).
          update_all(country: new_hashed_db_country)

    end

    update_nationality_hash.each do |old_nationality, new_nationality|

      puts "updating nationality-#{old_nationality}"

      hashed_db_nationality = Md5UserExtendedDetail.get_hashed_value(old_nationality)
      user_extended_detail_ids = Md5UserExtendedDetail.where(nationality: hashed_db_nationality).pluck(:user_extended_detail_id)
      puts "total rows to be updated-#{user_extended_detail_ids.length}"
      next if user_extended_detail_ids.blank?

      user_extended_detail_ids.each do |uedi|
        puts "updating ued row id-#{uedi}"
        ued = UserExtendedDetail.where(id: uedi).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        fail 'decryption of kyc salt failed.' unless r.success?

        kyc_salt_d = r.data[:plaintext]

        encryptor_obj = LocalCipher.new(kyc_salt_d)
        r = encryptor_obj.decrypt(ued.nationality)
        fail 'decryption of old nationality failed.' unless r.success?

        decrypted_nationality = r.data[:plaintext]

        fail "Country is different for id-#{uedi}" if decrypted_nationality.downcase != old_nationality.downcase

        r = encryptor_obj.encrypt(new_nationality)
        fail 'encryption of new nationality failed.' unless r.success?

        ued.nationality = r.data[:ciphertext_blob]
        ued.save!
      end

      new_hashed_db_nationality = Md5UserExtendedDetail.get_hashed_value(new_nationality)
      Md5UserExtendedDetail.where(user_extended_detail_id: user_extended_detail_ids,
                                  nationality: hashed_db_nationality).update_all(nationality: new_hashed_db_nationality)

    end

    puts "rake completed"

  end

end