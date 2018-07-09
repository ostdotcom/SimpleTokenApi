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
      # @ returns [Integer] 100 if dob match found
      #
      def compare
        percent_match = 0
        date_of_birth = Date.strptime(@match_string, "%Y-%m-%d")
        all_possible_date_number_regex_array = all_possible_date_number_regex(date_of_birth)

        if @paragraph.match(/#{all_possible_date_number_regex_array.join("|")}/i)
          percent_match = 100
        else
          all_month_name_regex_array = all_month_name_regex(date_of_birth)
          if @paragraph.match(/#{all_month_name_regex_array.join("|")}/i)
            percent_match = 100
          end
        end

        percent_match
      end

      # Get all possible regex number formats of a date (with month as integer)
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @returns [Array] all regex format of a date in number format
      #
      def all_possible_date_number_regex(date_obj)
        formats = []
        month = date_obj.month
        month = "0?#{month}" if month < 10

        day = date_obj.day
        day = "0?#{day}" if day < 10

        year = date_obj.strftime("%Y")
        year_short = date_obj.strftime("%y")

        # All possible formats includes these delimeters
        delimeters = ['/', '-', '.', ' ', ',', '']


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

        # special uncommon formats
        formats << "#{day}.#{month} #{year}"
        formats << "#{day}:#{month}-#{year}"
        formats << "#{month}/#{day} #{year}"
        formats << "#{day} #{month}-#{year}"
        formats << "#{day}#{month}/#{year}"

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
      def all_month_name_regex(date_obj)
        formats = []

        day = date_obj.day
        day = "0?#{day}" if day < 10

        year = date_obj.strftime("%Y")
        year_short = date_obj.strftime("%y")

        month_name = date_obj.strftime("%B")
        month_name_short = date_obj.strftime("%b")

        # Space/Slash/Pipe (0 or more occurences followed by a local month name string(\w*))
        month_str_regex_back = "([\s\/\|]*)(\\w*)"

        # local month name string(\w*) followed by  Space/Slash/Pipe (0 or more occurences)
        month_str_regex_front = "(\\w*)([\s\/\|]*)"

        # regex for full month name in english
        month_regex = "#{month_str_regex_front}#{month_name}#{month_str_regex_back}"

        # regex for short month name in english
        month_regex_short = "#{month_str_regex_front}#{month_name_short}#{month_str_regex_back}"

        str_delimeters = '-, /.'

        # todo: test delimeter_regex usage with valid and invalid test cases

        delimeter_regex = "[#{str_delimeters}]*"

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


        # Add UNUSUAL FORMATS if any

        return regex_from_formats(formats)
      end

    end
  end

end