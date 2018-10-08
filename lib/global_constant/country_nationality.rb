# frozen_string_literal: true
module GlobalConstant

  class CountryNationality
    require 'csv'

    # GlobalConstant::CountryNationality

    # Get Cynopsis Country From Ip
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.get_cynopsis_country_from_ip(ip_address)
      geoip_country = get_maxmind_country_from_ip(ip_address)
      return [] if geoip_country.blank?
      blacklisted_country = maxmind_to_cynopsis_country_hash[geoip_country.upcase]
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

    #  List of states disallowed to participate in ICO
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
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

    # list of cynopsis countries
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.countries
      @countries ||= cynopsis_country_to_maxmind_hash.keys
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

    # List of cynopsis nationalities
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]
    #
    def self.nationalities
      @nationalities ||= YAML.load_file(open(Rails.root.to_s + '/config/nationalities.yml'))[:nationalities]
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


    # Generate MD5 to cynopsis country name hash
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


    # Generate MD5 to cynopsis nationality name hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.nationality_md5_map
      @nationality_md5_map ||= generate_md5_map_for(nationalities)
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
        md5_value = Md5UserExtendedDetail.get_hashed_value(value)
        md5_map[md5_value] = value
      end
      md5_map
    end


    # Cynopsis country name to Maxmind country hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash] one cynopsis country can have multiple maxmind country name
    #
    def self.cynopsis_country_to_maxmind_hash
      @cynopsis_country_to_maxmind_hash ||= begin
        country_mapping = {}
        cynopsis_country_to_maxmind_data.each do |row|
          key = row[0].upcase
          value = row.drop(1)
          country_mapping[key] = value
        end
        country_mapping
      end
    end


    # Maxmind country name to Cynopsis country hash
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Hash]
    #
    def self.maxmind_to_cynopsis_country_hash
      @maxmind_to_cynopsis_country_hash ||= begin
        inverse_hash = {}
        cynopsis_country_to_maxmind_hash.each do |cynopsis_country, maxmind_countries|
          maxmind_countries.each do |maxmind_country|
            key = maxmind_country.upcase
            inverse_hash[key] ||= []
            inverse_hash[key] << cynopsis_country
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
    def self.cynopsis_country_to_maxmind_data
      @cynopsis_country_to_maxmind_data ||= CSV.read("#{Rails.root}/config/cynopsis_country_to_maxmind_mapping.csv")
    end

    # list of cynopsis countries removed from previous list of cynopsis countries
    #
    # * Author: Tejas
    # * Date: 01/08/2018
    # * Reviewed By: Aman
    #
    # @return [Array]  # these countries were deleted from our list of cynopsis country on 01/08/2018
    #
    def self.deleted_countries
      [
          "ASHMORE AND CARTIER ISLANDS",
          "AUSTRALIAN ANTARCTIC TERRITORY",
          "BAKER ISLAND",
          "BRITISH ANTARCTIC TERRITORY",
          "BRITISH SOVEREIGN BASE AREAS",
          "SAINT KITTS AND NEVIS"
      ]
    end

  end

end

# Countries :
# two countries can have same nationality.
# Cynopsis nationality file has repeated values as it is a mapping to the country list
# remove countries.yml file
# "DEMOCRATIC REPUBLIC OF THE CONGO" is not in our list while "CONGO (REPUBLIC OF),CONGO" is present
# WESTERN SAHARAN was changed to WESTERN SAHARA. we need to do run the migration for db.

# Nationalities:
# Remove two files. Have only nationality_and_country_mapping.
# Use  country_nationality.rb instead of nationality_country.rb
# ["AFGHANI", "BAHRAINIAN", "LITHUNIAN"] - needs to be changed to  ["AFGHAN", "BAHRAINI", "LITHUANIAN"]
#
# These 3 natioanlities have multiple rows in mapping file
# ALANDIC
# COMORAN
# LITHUANIAN
#
#
# LITHUNIAN,LTU,LITHUANIA,LIETUVOS,
# LITHUANIAN,LTU,LITHUANIA,LIETUVOS,
# LITHUANIAN,LTU,LITHUANIA,LIETUVOS,
#
# ALANDIC,ALA,ALAND ISLANDS,,
# ALANDIC,ALA,ALAND ISLANDS,,
#
# COMORAN,COM,COMOROS,,
# COMORAN,CMR,CAMEROONIAN,,
#
#
# It is in the list of deleted countries but it is a separate nationality as well .If they are to be removed, then remove natioanlity as well?
#
# AUSTRALIAN ANTARCTIC TERRITORY
# BAKER ISLAND
# BRITISH ANTARCTIC TERRITORY
# BRITISH SOVEREIGN BASE AREAS
# KITTIAN,KNA,SAINT KITTS AND NEVIS,, --- looks like a valid country with iso code


















# nationality_map, nationality,
#
# cynopsis, mapping
#
# #
# cynopsis.uniq.length = 255
# nationality.length = 254
# nationality_map.length = 268
#
#
# # mapping has 218 rows correct
# #
# #
# #
# #
# #
# #
#
#
#
#
# a = GlobalConstant::NationalityCountry.fetch_country_nationality_mapping
#
# mapping ||= {}
#
# a.each do |row|
#   sp = row.gsub("\r", "").split(",")
#   key = sp[0].upcase
#   mapping[key] = row
# end
#
#
# r = []
# dup_nationality = nationality.dup
# dup_mapping = mapping.dup
#
#
#
# nationality.each do |n|
#   data = mapping[n]
#
#   if data.present?
#     r << data
#     dup_nationality.delete(n)
#     dup_mapping.delete(n)
#   else
#
#   end
#
# end
#
# final = r
# final << []
# final << []
#
# dup_nationality.map{|x| final << ["#{x},,"]}
#
# final << []
# final << []
#
#
# final += dup_mapping.values
#






