# frozen_string_literal: true
module GlobalConstant

  class CountryNationality

    def self.disallowed_states
      {
          'united states of america' => {
              'newyork' => 'NY',
              'new york' => 'NY',
              'new york state' => 'NY',
              'newyorkstate' => 'NY',
              'new yorkstate' => 'NY',
              'ny' => 'NY',
              'nyc' => 'NY'
          },
          'ukraine' => {
              'crimea' => 'Crimea'
          },
          'russia' => {
              'crimea' => 'Crimea'
          }
      }
    end

    def self.countries
      @countries ||= YAML.load_file(open(Rails.root.to_s + '/config/countries.yml'))[:countries]
    end

    def self.country_name_for(md5_country)
      country_md5_map[md5_country] || ''
    end

    def self.nationalities
      @nationalities ||= YAML.load_file(open(Rails.root.to_s + '/config/nationalities.yml'))[:nationalities]
    end

    def self.nationality_name_for(md5_nationality)
      nationality_md5_map[md5_nationality] || ''
    end

    def self.is_nationality_chinese(nationality)
      nationality.upcase == 'CHINESE'
    end

    private

    def self.country_md5_map
      @country_md5_map ||= generate_md5_map_for(countries)
    end

    def self.nationality_md5_map
      @nationality_md5_map ||= generate_md5_map_for(nationalities)
    end

    def self.generate_md5_map_for(arr_list)
      md5_map = {}
      arr_list.each do |value|
        sha256_params = {
            string: value.to_s.strip,
            salt: GlobalConstant::SecretEncryptor.user_extended_detail_secret_key
        }
        md5_value = Sha256.new(sha256_params).perform
        md5_map[md5_value] = value
      end
      md5_map
    end

  end

end
