namespace :onetimer do

  # rake onetimer:get_kycs_of_given_country RAILS_ENV=staging

  task :get_kycs_of_given_country => :environment do

    countries = ['Sri Lanka','Tunisia']
    nationalities = ['Ugandan']

    usr_kyc_ids = {'Sri Lanka' => [], 'Tunisia' => [], 'Ugandan' => []}

    countries.each do |cntr|
      md5_cntry = Md5UserExtendedDetail.get_hashed_value(cntr)
      ued_ids = Md5UserExtendedDetail.where(country: md5_cntry).pluck(:user_extended_detail_id)

      usr_kyc_ids[cntr] += UserKycDetail.where(user_extended_detail_id: ued_ids).pluck(:id)
    end

    nationalities.each do |ntnl|
      md5_ntnl = Md5UserExtendedDetail.get_hashed_value(ntnl)
      ued_ids = Md5UserExtendedDetail.where(nationality: md5_ntnl).pluck(:user_extended_detail_id)

      usr_kyc_ids[ntnl] += UserKycDetail.where(user_extended_detail_id: ued_ids).pluck(:id)
    end

    puts "\n\n Countries => #{countries} \n\n Nationalities => #{nationalities}"
    puts "\n\n Case Ids: #{usr_kyc_ids.inspect}"

  end

end
