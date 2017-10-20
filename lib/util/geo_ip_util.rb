module Util

  class GeoIpUtil

    # Initialize
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By: Sunil
    #
    # Set @ip_address
    #
    def initialize(params)
      @ip_address = params[:ip_address]
    end

    # Fetch Location Details
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] Ip address for which location details are to be fetched
    #
    # @return [Hash]
    #
    def location_details
      @location_details ||= begin
        return {} unless GlobalConstant::GeoIp.maxmind_file_exists?
        ret = GlobalConstant::GeoIp.maxmind_obj.lookup(@ip_address)
        data = ret.found? ? ret.to_hash.deep_symbolize_keys! : {}
        data
      rescue => e
        Rails.logger.error("location_details failed with exception: for #{@ip_address} - #{e.message}")
        # Fail it for non production environments
        fail "location_details failed with exception: for #{@ip_address} - #{e.message}" unless Rail.env.production?
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
