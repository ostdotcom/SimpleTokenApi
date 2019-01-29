# frozen_string_literal: true
module GlobalConstant

  class CountryNationality
    require 'csv'

    # GlobalConstant::CountryNationality

    # Get Aml Country From Ip
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.get_aml_country_from_ip(ip_address)
      geoip_country = get_maxmind_country_from_ip(ip_address)
      return [] if geoip_country.blank?
      blacklisted_country = maxmind_to_aml_country_hash[geoip_country.upcase]
      blacklisted_country.present? ? blacklisted_country : []
    end

    # Get Maxmind Country From Ip
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [String]
    #
    def self.get_maxmind_country_from_ip(ip_address)
      geo_ip_obj = Util::GeoIpUtil.new(ip_address: ip_address)
      geoip_country = geo_ip_obj.get_country_name.to_s rescue ''
      geoip_country.to_s.upcase
    end

    # #  List of states disallowed to participate in ICO
    # #
    # # * Author: Tejas
    # # * Date: 01/08/2018
    # # * Reviewed By: Aman
    # #
    # # @return [Hash]
    # #
    # def self.disallowed_states
    #   {
    #       'united states of america' => {
    #           'newyork' => 'NY',
    #           'new york' => 'NY',
    #           'new york state' => 'NY',
    #           'newyorkstate' => 'NY',
    #           'new yorkstate' => 'NY',
    #           'ny' => 'NY',
    #           'nyc' => 'NY'
    #       },
    #       'ukraine' => {
    #           'crimea' => 'Crimea'
    #       },
    #       'russia' => {
    #           'crimea' => 'Crimea'
    #       }
    #   }
    # end

    # list of aml countries
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.countries
      @countries ||= aml_country_to_maxmind_hash.keys
    end

    # Get country name from its MD5 hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [String]
    #
    def self.country_name_for(md5_country)
      country_md5_map[md5_country] || ''
    end

    # List of aml nationalities
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.nationalities
      @nationalities ||= nationality_iso_map.keys
    end

    # Get nationality name from its MD5 hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [String]
    #
    def self.nationality_name_for(md5_nationality)
      nationality_md5_map[md5_nationality] || ''
    end

    private


    # Generate MD5 to aml country name hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.country_md5_map
      @country_md5_map ||= generate_md5_map_for(countries + deleted_countries)
    end


    # Generate MD5 to aml nationality name hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.nationality_md5_map
      @nationality_md5_map ||= generate_md5_map_for(nationalities + deleted_nationalities)
    end


    # Generate the MD5 map of an array of string
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.generate_md5_map_for(arr_list)
      md5_map = {}
      arr_list.each do |value|
        md5_value = Md5UserExtendedDetail.use_any_instance.get_hashed_value(value)
        md5_map[md5_value] = value
      end
      md5_map
    end


    # Aml country name to Maxmind country hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash] one aml country can have multiple maxmind country name
    #
    def self.aml_country_to_maxmind_hash
      @aml_country_to_maxmind_hash ||= begin
        country_mapping = {}
        aml_country_to_maxmind_data.each do |row|
          key = row[0].upcase
          value = row.drop(1)
          country_mapping[key] = value
        end
        country_mapping
      end
    end


    # Maxmind country name to Aml country hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.maxmind_to_aml_country_hash
      @maxmind_to_aml_country_hash ||= begin
        inverse_hash = {}
        aml_country_to_maxmind_hash.each do |aml_country, maxmind_countries|
          maxmind_countries.each do |maxmind_country|
            key = maxmind_country.upcase
            inverse_hash[key] ||= []
            inverse_hash[key] << aml_country
          end
        end
        inverse_hash
      end
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.aml_country_to_maxmind_data
      @aml_country_to_maxmind_data ||= CSV.read("#{Rails.root}/config/aml_country_to_maxmind_mapping.csv")
    end

    # list of cynopsis nationalities removed from previous list of cynopsis nationalities
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]  # these nationalities were deleted from our list of cynopsis nationalities on 02/11/2018
    #
    def self.deleted_nationalities
      [
          "ASCENSION",
          "TRISTAN DA CUNHA",
          "BRITISH INDIAN OCEAN TERRITORY",
          "AUSTRALIAN ANTARCTIC TERRITORY",
          "BAKER ISLAND",
          "BRITISH ANTARCTIC TERRITORY",
          "BRITISH SOVEREIGN BASE AREAS",
          "JARVIS ISLAND",
          "FRENCH SOUTHERN AND ANTARCTIC LANDS",
          "CLIPPERTON ISLAND",
          "ROSS DEPENDENCY",
          "QUEEN MAUD LAND",
          "PETER I ISLAND"
      ]
    end

    # list of aml countries removed from previous list of aml countries
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]  # these countries were deleted from our list of aml country on 01/08/2018
    #
    def self.deleted_countries
      [

          # countries which were removed from  cynopsis list previously
          "BRITISH INDIAN OCEAN TERRITORY",
          "ASHMORE AND CARTIER ISLANDS",
          "AUSTRALIAN ANTARCTIC TERRITORY",
          "BAKER ISLAND",
          "BRITISH ANTARCTIC TERRITORY",
          "BRITISH SOVEREIGN BASE AREAS",
          "JARVIS ISLAND",
          "FRENCH SOUTHERN AND ANTARCTIC LANDS",
          "CLIPPERTON ISLAND",
          "ROSS DEPENDENCY",
          "QUEEN MAUD LAND",
          "PETER I ISLAND",

          # countries not in acuris list
          "ANTARCTICA",
          "FRENCH SOUTHERN TERRITORIES",
          "HOWLAND ISLAND",
          "KINGMAN REEF",
          "NAGORNO-KARABAKH",
          "PRIDNESTROVIE (TRANSNISTRIA)",
          "SOUTH OSSETIA",
          "UNITED STATES MINOR OUTLYING ISLANDS"
      ]
    end

    # Usa States with space regex to handle multiple or 0 spaces
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def self.regex_usa_states
      @regex_usa_states ||= begin
        arr = []
        usa_states.each do |state|
          arr << Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(state)
        end
        arr
      end
    end

    # canada States with space regex to handle multiple or 0 spaces
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def self.regex_canada_states
      @regex_canada_states ||= begin
        arr = []
        canada_states.each do |state|
          arr << Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(state)
        end
        arr
      end
    end

    # Usa States
    #
    # * Author: Tejas
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Array]
    #
    def self.usa_states
      ['USA', 'United States Minor Outlying Islands', 'United States of America',
       'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida',
       'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
       'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana Nebraska', 'Nevada', 'New Hampshire',
       'New Jersey', 'New Mexico', 'New York', 'Dakota', 'Ohio', 'Oklahoma', 'Oregon',
       'Carolina', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia',
       'Washington', 'West Virginia', 'Wisconsin', 'Wyoming', 'CAROLINA', 'Pennsylvania', 'Rhode Island']
    end

    # Canada States
    #
    # * Author: Tejas
    # * Date: 10/07/2018
    # * Reviewed By:
    #
    # @return [Array]
    #
    def self.canada_states
      ['Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador	',
       'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories',
       'Nunavut', 'Yukon']
    end

    # Nationality Country Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #

    def self.nationality_country_map
      generate_nationality_country_map
    end

    # Nationality Iso Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def self.nationality_iso_map
      generate_nationality_iso_map
    end


    # Generate Nationality Country Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash] nationality_country_mapping
    #

    def self.generate_nationality_country_map
      @nationality_country_mapping ||= {}
      if @nationality_country_mapping.blank?
        fetch_country_nationality_mapping.each do |row|
          sp = row.gsub("\r", "").split(",")
          key = sp[0].upcase
          val = sp.drop(2)
          @nationality_country_mapping[key] = val
        end
      end

      @nationality_country_mapping

    end

    # Generate Nationality Iso Map
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Hash] nationality_iso_mapping
    #

    def self.generate_nationality_iso_map
      @nationality_iso_mapping ||= {}
      if @nationality_iso_mapping.blank?
        fetch_country_nationality_mapping.each do |row|
          sp = row.gsub("\r", "").split(",")
          key = sp[0].upcase
          value = sp[1].upcase
          @nationality_iso_mapping[key] = value
        end
      end

      @nationality_iso_mapping

    end

    # Fetch Country Nationality Mapping
    #
    # * Author: Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return Array[String] fetch_file_contents
    #
    def self.fetch_country_nationality_mapping
      @fetch_file_contents ||= File.open("#{Rails.root}/config/nationality_and_country_mapping.csv",
                                         "rb").read.split("\n")
    end

    # Updated Country Hash By Cynopsis

    # renamed country hash for difference in cynopsis and acuris
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #

    def self.updated_country_hash
      {
          "BAHAMAS" => "BAHAMAS, THE",
          "BURMA (REPUBLIC OF THE UNION OF MYANMAR)" => "MYANMAR",
          "CARIBBEAN NETHERLANDS" => "NETHERLANDS ANTILLES",
          "CAYMAN ISLANDS" => "CAYMAN ISLANDS, THE",
          "CONGO (REPUBLIC OF)" => "CONGO, REPUBLIC OF THE",
          "COTE D'IVOIRE (IVORY COAST)" => "CÔTE D'IVOIRE",
          "DEMOCRATIC REPUBLIC OF THE CONGO" => "CONGO, DEMOCRATIC REPUBLIC OF THE",
          "GAMBIA" => "GAMBIA, THE",
          "MACEDONIA" => "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF",
          "MICRONESIA" => "MICRONESIA, FEDERATED STATES OF",
          "NORTH KOREA" => "KOREA, NORTH",
          "RUSSIAN FEDERATION" => "RUSSIA",
          "SAINT MARTIN (NETHERLANDS)" => "ST. MAARTEN",
          "SAINT VINCENT AND GRENADINES" => "SAINT VINCENT AND THE GRENADINES",
          "SOMALILAND" => "SOMALIA",
          "SOUTH KOREA" => "KOREA, SOUTH",
          "TIMOR-LESTE" => "EAST TIMOR",
          "VATICAN" => "VATICAN CITY",
          "WALLIS AND FUTUNA ISLANDS" => "WALLIS AND FUTUNA",


          "ABKHAZIA"=> 'GEORGIA',
          "ALAND ISLANDS"=> 'FINLAND',
          "ASCENSION"=> 'UNITED KINGDOM',
          "BOUVET ISLAND"=> 'NORWAY',
          "CHRISTMAS ISLAND"=> 'AUSTRALIA',
          "COCOS (KEELING) ISLANDS"=> 'AUSTRALIA',
          "CORAL SEA ISLANDS"=> 'AUSTRALIA',
          "CURACAO"=> 'NETHERLANDS ANTILLES', # as per google
          "FALKLAND ISLANDS"=> 'UNITED KINGDOM',
          "HEARD AND MCDONALD ISLANDS"=> 'AUSTRALIA',
          "JOHNSTON ATOLL"=> 'UNITED STATES OF AMERICA',
          "MIDWAY ISLANDS"=> 'UNITED STATES OF AMERICA',
          "NAVASSA ISLAND"=> 'UNITED STATES OF AMERICA',
          "NORTHERN CYPRUS"=> 'CYPRUS',
          "PALMYRA ATOLL"=> 'UNITED STATES OF AMERICA',
          "PITCAIRN"=> 'UNITED KINGDOM',
          "PITCAIRN ISLANDS"=> 'UNITED KINGDOM',
          "SAINT BARTHELEMY"=> 'FRANCE',
          "SAINT HELENA"=> 'UNITED KINGDOM',
          "SAINT MARTIN (FRANCE)"=> 'FRANCE',
          "SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS"=> 'UNITED KINGDOM',
          "SVALBARD AND JAN MAYEN ISLANDS"=> 'NORWAY',
          "TOKELAU"=> 'NEW ZEALAND',
          "TRISTAN DA CUNHA"=> 'UNITED KINGDOM',
          "WAKE ISLAND" => 'UNITED STATES OF AMERICA'
      }

    end

    # Updated Nationality Hash By Cynopsis
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.updated_nationality_hash
      {
          "AFGHANI" => "AFGHAN",
          "BAHRAINIAN" => "BAHRAINI",
          "LITHUNIAN" => "LITHUANIAN"
      }
    end


  end

end
