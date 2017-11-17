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

    def self.is_residence_proof_mandatory?(nationality)
      residency_proof_mandatory_for_countries.include?(nationality.upcase)
    end

    def self.residency_proof_mandatory_for_countries
      [
          'CHINESE',
          'NEW ZEALANDER',
          'AFGHANI',
          'BOSNIAN',
          'CENTRAL AFRICAN',
          'CONGOLESE',
          'CUBAN',
          'ERITREAN',
          'ETHIOPIAN',
          'IRANIAN',
          'IRAQI',
          'LEBANESE',
          'LIBYAN',
          'NORTH KOREAN',
          'SOMALI',
          'SOUTH SUDANESE',
          'SUDANESE',
          'SRI LANKAN',
          'SYRIAN',
          'TUNISIAN',
          'NI-VANUATU',
          'YEMENI'
      ]
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
        md5_value = Md5UserExtendedDetail.get_hashed_value(value)
        md5_map[md5_value] = value
      end
      md5_map
    end

  end

end
