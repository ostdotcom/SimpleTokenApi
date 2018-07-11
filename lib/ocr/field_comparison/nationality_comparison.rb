module Ocr

  module FieldComparison

    class NationalityComparison < Base

      # @return [Ocr::FieldComparison::NationalityComparison.new()]

      private

      # Compare
      #
      # * Author: Tejas
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @return [Integer]
      #

      def compare
        @match_string = safe_characters(@match_string)
        return 100 if @safe_line_array.match(/#{@match_string}/i)
        if ['american', 'U.S. TERRITORY'.downcase].include?(@match_string.downcase)
          usa_states.each{|uss| return 100 if @safe_line_array.match(/#{uss}/i)}
        else
          country = nationalities_mapping[@match_string.downcase]
          return 0 if country.blank?
          country.each do |entry|
            return 100 if entry.present? and @safe_line_array.match(/#{entry}/i)
          end
        end
        0
      end

      # Nationalities Mapping
      #
      # * Author: Tejas
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @return [Hash] nationality_map
      #

      def nationalities_mapping

        @nationality_map ||= {}
        if @nationality_map.blank?
          file = File.open("#{Rails.root}/country_nationality.csv", "rb")
          file.each do |row|
            sp = row.gsub("\r\n", "").split(",")
            @nationality_map[sp[1].downcase] ||= []
            @nationality_map[sp[1].downcase] << sp[0]
          end
          # return 0 if @nationality_map.blank?
        end

        @nationality_map

      end

      # Usa States
      #
      # * Author: Tejas
      # * Date: 02/07/2018
      # * Reviewed By:
      #
      # @return [String]
      #

      def usa_states
        return ['USA','United States Minor Outlying Islands','United States of America',
                'Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida',
                'Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland',
                'Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana Nebraska','Nevada','New Hampshire',
                'New Jersey','New Mexico','New York','Dakota','Ohio','Oklahoma','Oregon',
                'Carolina','Tennessee','Texas','Utah','Vermont','Virginia',
                'Washington','West Virginia','Wisconsin','Wyoming','CAROLINA', 'Pennsylvania', 'Rhode Island']
      end
    end
  end
end
