module Util

  class GeoIpUtil

    # maxmind file present in local
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def self.maxmind_file_exists?
      File.exists?(maxmind_db_data_file_path)
    end

    # local path to Maxmind DB Data File
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By:
    #
    # @return [String]
    #
    def self.maxmind_db_data_file_path
      @maxmind_db_data_file_path ||= "#{Rails.root}/../GeoLite2-City.mmdb"
    end

    # Initialize
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By:
    #
    # Set @maxmind_db_object
    #
    def initialize(params)
      @maxmind_db_object = ::MaxMindDB.new(::Util::GeoIpUtil.maxmind_db_data_file_path)
      @ip_address = params[:ip_address]
    end

    # Fetch Location Details
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By:
    #
    # @param [String] Ip address for which location details are to be fetched
    #
    # @return [Hash]
    #
    def location_details
      @location_details ||= begin
        ret = @maxmind_db_object.lookup(@ip_address)
        data = ret.found? ? ret.to_hash.deep_symbolize_keys! : {}
        data
      rescue => e
        {}
      end
    end

    def country_data
      location_details[:registered_country] || location_details[:country] || {}
    end

    def get_country_name
      return (country_data[:names] || {})[:en]
    end

    def get_country_iso_code
      return country_data[:iso_code]
    end

  end

end
