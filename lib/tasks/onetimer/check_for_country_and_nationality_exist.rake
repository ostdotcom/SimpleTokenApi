namespace :onetimer do


  # params = {
  #     "country_array" => ["BRITISH INDIAN OCEAN TERRITORY",
  # "AUSTRALIAN ANTARCTIC TERRITORY",
  # "BAKER ISLAND",
  # "BRITISH ANTARCTIC TERRITORY",
  # "BRITISH SOVEREIGN BASE AREAS",
  # "JARVIS ISLAND",
  # "FRENCH SOUTHERN AND ANTARCTIC LANDS",
  # "CLIPPERTON ISLAND",
  # "ROSS DEPENDENCY",
  # "QUEEN MAUD LAND",
  # "PETER I ISLAND"] ,
  #
  #     "nationality_array" => ["ASCENSION",
  # "TRISTAN DA CUNHA",
  # "BRITISH INDIAN OCEAN TERRITORY",
  # "AUSTRALIAN ANTARCTIC TERRITORY",
  # "BAKER ISLAND",
  # "BRITISH ANTARCTIC TERRITORY",
  # "BRITISH SOVEREIGN BASE AREAS",
  # "JARVIS ISLAND",
  # "FRENCH SOUTHERN AND ANTARCTIC LANDS",
  # "CLIPPERTON ISLAND",
  # "ROSS DEPENDENCY",
  # "QUEEN MAUD LAND",
  # "PETER I ISLAND"]
  # }

  # params = params.to_json
  # rake RAILS_ENV=development onetimer:check_for_country_and_nationality_exist params="{\"country_array\":[\"BRITISH INDIAN OCEAN TERRITORY\",\"AUSTRALIAN ANTARCTIC TERRITORY\",\"BAKER ISLAND\",\"BRITISH ANTARCTIC TERRITORY\",\"BRITISH SOVEREIGN BASE AREAS\",\"JARVIS ISLAND\",\"FRENCH SOUTHERN AND ANTARCTIC LANDS\",\"CLIPPERTON ISLAND\",\"ROSS DEPENDENCY\",\"INDIA\",\"QUEEN MAUD LAND\",\"PETER I ISLAND\"],\"nationality_array\":[\"ASCENSION\",\"TRISTAN DA CUNHA\",\"BRITISH INDIAN OCEAN TERRITORY\",\"AUSTRALIAN ANTARCTIC TERRITORY\",\"BAKER ISLAND\",\"BRITISH ANTARCTIC TERRITORY\",\"BRITISH SOVEREIGN BASE AREAS\",\"JARVIS ISLAND\",\"INDIAN\",\"FRENCH SOUTHERN AND ANTARCTIC LANDS\",\"CLIPPERTON ISLAND\",\"ROSS DEPENDENCY\",\"QUEEN MAUD LAND\",\"PETER I ISLAND\"]}"

  # Check For Country And Nationality Exist
  #
  # * Author: Tejas
  # * Date: 27/07/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:check_for_country_and_nationality_exist
  #
  task :check_for_country_and_nationality_exist => :environment do

    params = JSON.parse(ENV['params'])

    country_array = params["country_array"]
    nationality_array = params["nationality_array"]
    countries_present_in_db = {}
    nationality_present_in_db = {}
    countries_present_in_blacklisted_countries = {}
    nationality_present_in_residency_proof_nationalities = {}

    country_array.each do |country|
      ClientKycConfigDetail.all.each do |row|
        blacklisted_countries = row.blacklisted_countries
        countries_present_in_blacklisted_countries[country]=  row.client_id if blacklisted_countries.include?(country)
      end

      # todo shard support
      hashed_db_country = Md5UserExtendedDetail.get_hashed_value(country)
      user_extended_detail_ids = Md5UserExtendedDetail.where(country: hashed_db_country).pluck(:user_extended_detail_id)
      puts "The country #{country} is present in our DB." if user_extended_detail_ids.present?
      countries_present_in_db[country]=  user_extended_detail_ids.length if user_extended_detail_ids.present?
    end

    nationality_array.each do |nationality|
      ClientKycConfigDetail.all.each do |row|
        residency_proof_nationalities = row.residency_proof_nationalities
        nationality_present_in_residency_proof_nationalities[nationality]=  row.client_id if residency_proof_nationalities.include?(nationality)
      end

      hashed_db_nationality = Md5UserExtendedDetail.get_hashed_value(nationality)
      user_extended_detail_ids = Md5UserExtendedDetail.where(country: hashed_db_nationality).pluck(:user_extended_detail_id)
      puts "The nationality #{nationality} is present in our DB." if user_extended_detail_ids.present?
      nationality_present_in_db[nationality]=  user_extended_detail_ids.length if user_extended_detail_ids.present?
    end



    puts nationality_present_in_db
    puts countries_present_in_db
    puts countries_present_in_blacklisted_countries
    puts nationality_present_in_residency_proof_nationalities

    puts "rake completed!!!"

  end

end