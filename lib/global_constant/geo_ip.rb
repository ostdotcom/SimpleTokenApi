# frozen_string_literal: true
module GlobalConstant

  class GeoIp

    class << self

      def maxmind_file_exists?
        @maxmind_file_exists ||= File.exists?(GlobalConstant::LocalPath.geo_ip_file)
      end

      def maxmind_obj
        @maxmind_obj ||= ::MaxMindDB.new(GlobalConstant::LocalPath.geo_ip_file)
      end

    end

  end

end
