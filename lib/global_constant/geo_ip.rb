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

      def blaclisted_ip_from_countries
        [
            'china',
            'afghanistan',
            'bosnia and herzegovina',
            'central african republic',
            'congo',
            'north korea',
            'eritrea',
            'ethiopia',
            'guinea-bissau',
            'iran',
            'iraq',
            'libya',
            'lebanon',
            'somalia',
            'south sudan',
            'sudan',
            'syria',
            'uganda',
            'vanuatu',
            'yemen',
            'cuba'
        ]
      end

    end

  end

end
