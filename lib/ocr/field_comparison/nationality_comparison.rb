module Ocr

  module FieldComparison

    class NationalityComparison < Base

      # Initialize
      #
      # * Author: Tejas
      # * Date: 09/07/2018
      # * Reviewed By:
      #
      # @return [Ocr::FieldComparison::NationalityComparison]
      #

      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 09/07/2018
      # * Reviewed By:
      #
      # @return [Integer]

      def perform
        super
      end

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
        @paragraph =  Util::CommonValidateAndSanitize.safe_paragraph(@paragraph)
        iso_map = GlobalConstant::NationalityCountry.nationality_iso_map
        iso_code = iso_map[@match_string.to_s.upcase]
        country_map = GlobalConstant::NationalityCountry.nationality_country_map
        country = country_map[@match_string.to_s.upcase]

        @paragraph.split("\n").each do |line|
          # full word match in a line
          next if line.blank?
          return 100 if line.match(/#{@match_string}/i)

          # country match in the line
          country.present? && country.each do |entry|
            return 100 if entry.present? and line.match(/#{entry}/i)
          end

          # check for american and u.s. territory and canada
          if ['american', 'u.s. territory'].include?(@match_string.downcase)
            usa_states.each{|uss| return 100 if line.match(/#{uss}/i)}
          elsif ['canadian'].include?(@match_string.downcase)
            canada_states.each{|uss| return 100 if line.match(/#{uss}/i)}
          end

          # check for ISO in machine-readable passport
          # remove any space in the Machine-readable_passport line
          next if iso_code.blank?
          next unless line.downcase.match(/p</)
          return 100 if passport_nationality_matched?(line, iso_code)

        end
        0
      end



      # words split by "{<}, {\s}" in a machine readable passport line has all the words in a name
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Boolean]

      def passport_nationality_matched?(line, iso_code)
        return false if !is_machine_readable_passport_line?(line)

        # remove any extra characters before the Machine-readable_passport line
        line = line.sub(/[^p]*p</, '')

        passport_iso = line.to_s[0..2]
        return true if passport_iso.downcase == iso_code.downcase
        return false
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

      # Canada States
      #
      # * Author: Tejas
      # * Date: 10/07/2018
      # * Reviewed By:
      #
      # @return [String]
      #
      def canada_states
        return ['Alberta','British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador	',
                'Nova Scotia', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Northwest Territories',
                'Nunavut', 'Yukon']
      end

    end
  end
end



# def compare
#   iso_map = GlobalConstant::NationalityCountry.nationality_iso_map
#   iso_code = iso_map[@match_string.to_s.upcase]
#   country_map = GlobalConstant::NationalityCountry.nationality_country_map
#   country = country_map[@match_string.to_s.upcase]
#
#   @paragraph.split("\n").each do |line|
#     # full word match in a line
#     next if line.blank?
#     return 100 if line.match(/#{@match_string}/i)
#
#     # country match in the line
#     country.present? && country.each do |entry|
#       return 100 if entry.present? and line.match(/#{entry}/i)
#     end
#
#     # check for american and u.s. territory and canada
#     if ['american', 'u.s. territory'].include?(@match_string.downcase)
#       usa_states.each{|uss| return 100 if line.match(/#{uss}/i)}
#     elsif ['canadian'].include?(@match_string.downcase)
#       canada_states.each{|uss| return 100 if line.match(/#{uss}/i)}
#     end
#
#
#     # check for ISO in machine-readable passport
#     # remove any space in the Machine-readable_passport line
#
#     next if iso_code.blank?
#     return 100 if passport_nationality_matched?(line, iso_code)
#
#     #
#     # next unless line.downcase.match(/p</)
#     # # remove any extra characters before the Machine-readable_passport line
#     # formatted_line = line.sub(/[^p]*p</, '')
#     # next if formatted_line.blank?
#     # passport_iso_code = line.to_s[2..4]
#     # return 100 if passport_iso_code == iso_code
#
#   end
#   0
# end
#
