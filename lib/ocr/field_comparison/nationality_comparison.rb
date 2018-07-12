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

        iso_code = GlobalConstant::NationalityCountry.nationality_iso_map[@match_string.to_s.upcase]
        country = GlobalConstant::NationalityCountry.nationality_country_map[@match_string.to_s.upcase]

        regex_match_string = Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(@match_string)

        regex_countries = country.blank? ? [] :
                              country.map {|x| Util::CommonValidateAndSanitize.get_words_regex_for_multi_space_support(x)}


        @paragraph.split("\n").each do |line|
          # full word match in a line
          next if line.blank?
          return 100 if line.match(/#{regex_match_string}/i)
          # country match in the line
          regex_countries.each do |entry|
            return 100 if line.match(/#{entry}/i)
          end

          # check for ISO in machine-readable passport
          # remove any space in the Machine-readable_passport line
          next if iso_code.blank?
          return 100 if passport_nationality_matched?(line, iso_code)
        end

        # check for american and u.s. territory and canada
        if ['american', 'u.s. territory'].include?(@match_string.downcase)
          GlobalConstant::NationalityCountry.regex_usa_states.each do |state|
            return 100 if @paragraph.match(/#{state}/i)
          end

        elsif ['canadian'].include?(@match_string.downcase)
          GlobalConstant::NationalityCountry.regex_canada_states.each do |state|
            return 100 if @paragraph.match(/#{state}/i)
          end
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
        line = sanitize_machine_readable_passport_line(line)
        return false if line.blank?

        passport_iso = line[2..4].to_s
        return true if passport_iso == iso_code.downcase
        return false
      end



    end
  end
end
