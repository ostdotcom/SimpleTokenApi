module Ocr

  module FieldComparison

    class BirthdateComparison < Base

      # @return [Ocr::FieldComparison::BirthdateComparison]

      # Initialize
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      def perform
        super
      end

      private

      # compare birthdate field in document
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Integer] 100 if dob match found
      #
      def compare
        percent_match = 0

        return 100 if passport_line_has_birthdate_match?

        all_possible_date_number_regex_array = all_possible_date_number_regex

        if @paragraph.match(/#{all_possible_date_number_regex_array.join("|")}/i)
          percent_match = 100
        else
          all_month_name_regex_array = all_month_name_regex
          if @paragraph.match(/#{all_month_name_regex_array.join("|")}/i)
            percent_match = 100
          end
        end

        percent_match
      end

      # check if birthdate in format YYMMDD is present in second machine readable line
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Boolean] gives true if dob match found
      #
      def passport_line_has_birthdate_match?
        last_line_was_passport_line = false

        @paragraph.split("\n").each do |line|
          is_passport_line = is_machine_readable_passport_line?(line)

          next unless is_passport_line || last_line_was_passport_line
          formatted_line = line.gsub(/ /, '')

          return true if formatted_line.match(/#{year_short}#{month}#{day}/i)
          last_line_was_passport_line = is_passport_line
        end

        return false
      end

      # Get all possible regex number formats of a date (with month as integer)
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Array] all regex format of a date in number format
      #
      def all_possible_date_number_regex
        formats = []

        # All possible formats includes these delimeters

        delimeters = ['/', '-', '\.', ' ']

        delimeters.each do |delimeter|
          # \s* makes sure that any whitepace character (0 or more) if present is neglected
          delimeter = "\s*#{delimeter}\s*"
          formats << "#{day}#{delimeter}#{month}#{delimeter}#{year}"
          formats << "#{year}#{delimeter}#{month}#{delimeter}#{day}"
          formats << "#{month}#{delimeter}#{day}#{delimeter}#{year}"
          formats << "#{month}#{delimeter}#{year}#{delimeter}#{day}"

          formats << "#{day}#{delimeter}#{month}#{delimeter}#{year_short}"
          formats << "#{year_short}#{delimeter}#{month}#{delimeter}#{day}"
          formats << "#{month}#{delimeter}#{day}#{delimeter}#{year_short}"
          formats << "#{month}#{delimeter}#{year_short}#{delimeter}#{day}"
        end

        # special uncommon formats not used
        # formats << "#{day}\.#{month} #{year}"   count - 8
        # formats << "#{day}:#{month}-#{year}"    count - 1
        # formats << "#{month}/#{day} #{year}"    count - 1
        # formats << "#{day} #{month}-#{year}"    count - 2
        # formats << "#{day}#{month}/#{year}"     count - 3

        return regex_from_formats(formats)
      end

      # Create regex to be used while matching dob from given format array
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Array] all regex format of a date
      #
      def regex_from_formats(formats_array)
        formats_array.map {|x| "(#{x})"}
      end

      # Get all possible regex formats of a date with month name
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Array] all regex format of a date with month name
      #
      def all_month_name_regex
        formats = []

        # Space/Slash/Pipe (0 or more occurences followed by a local month name string([a-z]*))
        # [a-z] can be replaced by [[:alpha:]] but then regex matching is very slow
        #
        month_str_regex_back = "([\s\/\|]*)([a-z]*)" # [a-z] can be replaced by [[:alpha:]] but then regex matching is very slow

        # local month name string(\w*) followed by  Space/Slash/Pipe (0 or more occurences)
        month_str_regex_front = "([a-z]*)([\s\/\|]*)"

        # regex for full month name in english
        month_regex = "#{month_str_regex_front}#{month_name}#{month_str_regex_back}"

        # regex for short month name in english
        month_regex_short = "#{month_str_regex_front}#{month_name_short}#{month_str_regex_back}"

        str_delimeters = ['/', '-', '\.', ' ']

        str_delimeters.each do |str_delimeter|
          delimeter_regex = "\s*#{str_delimeter}\s*"


          # ALL COMBINATION IS REPETED TWICE FOR year & year_short
          formats << "#{day}#{delimeter_regex}#{month_regex}#{delimeter_regex}#{year}"
          formats << "#{day}#{delimeter_regex}#{month_regex}#{delimeter_regex}#{year_short}"

          formats << "#{year}#{delimeter_regex}#{month_regex}#{delimeter_regex}#{day}"
          formats << "#{year_short}#{delimeter_regex}#{month_regex}#{delimeter_regex}#{day}"


          formats << "#{month_regex}#{delimeter_regex}#{day}#{delimeter_regex}#{year}"
          formats << "#{month_regex}#{delimeter_regex}#{day}#{delimeter_regex}#{year_short}"

          formats << "#{month_regex}#{delimeter_regex}#{year}#{delimeter_regex}#{day}"
          formats << "#{month_regex}#{delimeter_regex}#{year_short}#{delimeter_regex}#{day}"


          # ABOVE COMBINATION IS REPETED FOR month_regex_short

          formats << "#{day}#{delimeter_regex}#{month_regex_short}#{delimeter_regex}#{year}"
          formats << "#{day}#{delimeter_regex}#{month_regex_short}#{delimeter_regex}#{year_short}"

          formats << "#{year}#{delimeter_regex}#{month_regex_short}#{delimeter_regex}#{day}"
          formats << "#{year_short}#{delimeter_regex}#{month_regex_short}#{delimeter_regex}#{day}"

          formats << "#{month_regex_short}#{delimeter_regex}#{day}#{delimeter_regex}#{year}"
          formats << "#{month_regex_short}#{delimeter_regex}#{day}#{delimeter_regex}#{year_short}"

          formats << "#{month_regex_short}#{delimeter_regex}#{year}#{delimeter_regex}#{day}"
          formats << "#{month_regex_short}#{delimeter_regex}#{year_short}#{delimeter_regex}#{day}"
        end

        return regex_from_formats(formats)
      end

      def day
        @day ||= begin
          v = date_obj.day
          v = "0#{v}" if v < 10
          v
        end
      end

      def month
        @month ||= begin
          v = date_obj.month
          v = "0#{v}" if v < 10
          v
        end
      end

      def month_name
        @month_name ||= date_obj.strftime("%B")
      end

      def month_name_short
        @month_name_short ||= date_obj.strftime("%b")
      end

      def year_short
        @year_short ||= date_obj.strftime("%y")
      end

      def year
        @year ||= date_obj.strftime("%Y")
      end

      def date_obj
        @date_obj ||= Date.strptime(@match_string, "%Y-%m-%d")
      end

    end
  end

end