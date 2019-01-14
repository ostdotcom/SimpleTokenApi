namespace :onetimer do

  # Insert blacklisted_countries in ClientKycConfigDetail from ClientTemplate
  #
  # * Author: Tejas
  # * Date: 27/07/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:backpopulate_blacklisted_countries_in_client_kyc_config_details
  #
  task :backpopulate_blacklisted_countries_in_client_kyc_config_details => :environment do
    client_id_from_ckcd = ClientKycConfigDetail.pluck(:client_id)
    ClientTemplate.where(template_type: GlobalConstant::ClientTemplate.common_template_type, client_id: [client_id_from_ckcd]).all.each do |cts|

      blacklisted_countries_from_maxmind = cts.data[:blacklisted_countries].map(&:upcase)
      blacklisted_countries = []
      blacklisted_countries_from_maxmind.each do |country|
        aml_country = GlobalConstant::CountryNationality.maxmind_to_aml_country_hash[country]
        if aml_country.blank?
          puts "could not find mapping for country- #{country}"
        else
          blacklisted_countries += aml_country
        end
      end
      blacklisted_countries.uniq!

      client_id = cts.client_id
      client_kyc_config_detail = ClientKycConfigDetail.where(client_id:client_id).first
      # next if client_kyc_config_detail.nil?
      client_kyc_config_detail.blacklisted_countries = blacklisted_countries
      client_kyc_config_detail.save!
    end

  end


end