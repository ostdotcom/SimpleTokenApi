module OcrMatch
  class BirthdateMatch

    # Initialize
    # @params [Array] words_array(mandatory)
    # @params [String] match_string(mandatory)
    #
    # Sets @words_array, @match_string
    #
    # @return [OcrMatch::NameMatch.new()]
    #
    #* Author: Tejas
    #* Date: 28/06/2018
    #* Reviewed By:
    #
    def initialize(words_array, match_string)
      @words_array = words_array
      @match_string = match_string
      @safe_words_array = ""

    end

    # Perform
    #
    #* Author: Tejas
    #* Date: 28/06/2018
    #* Reviewed By:
    #
    # @return BOOL
    #

    def perform

      @safe_words_array = safe_characters(@words_array)

      return 0 if @safe_words_array.blank?
      return 50 if @match_string.blank?


      compare
    end

    private

    def safe_characters(characters)
      return if characters.blank?
      safe_paragraph = ""
      characters.each_char do |letter|
        safe_letter = letter.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
        safe_letter = letter.parameterize if safe_letter.blank?
        safe_paragraph += safe_letter.present? ? safe_letter : letter
      end
      safe_paragraph
    end

    def compare
      percent_match = 0
      date_of_birth = Date.strptime(@match_string, "%Y-%m-%d")
      all_possible_date_number_regex_array = all_possible_date_number_regex(date_of_birth)

      if @safe_words_array.match(/#{all_possible_date_number_regex_array.join("|")}/i)
        percent_match = 100
      else
        all_month_name_regex_array = all_month_name_regex(date_of_birth)
        if @safe_words_array.match(/#{all_month_name_regex_array.join("|")}/i)
          percent_match = 100
        end
      end

      if percent_match < 100
        date_of_birth = Date.strptime(@match_string, "%Y-%m-%d").strftime("%y%m%d")
        obj["#{column_name}_match_percent"] = 100 if @safe_words_array.match(date_of_birth)
      end
      percent_match
    end


    def all_possible_date_number_regex(date_obj)
      formats = []
      month = date_obj.month
      month = "0?#{month}" if month < 10

      day = date_obj.day
      day = "0?#{day}" if day < 10

      year = date_obj.strftime("%Y")
      year_short = date_obj.strftime("%y")

      delimeters = ['/', '-', '.', ' ', ',', '']

      delimeters.each do |delimeter|
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

      formats << "#{day}.#{month} #{year}"
      formats << "#{day}#{month}#{year}"
      formats << "#{day}:#{month}-#{year}"

      formats << "#{month}/#{day} #{year}"
      formats << "#{day} #{month}-#{year}"
      formats << "#{day}#{month}/#{year}"

      return regex_from_formats(formats)
    end


    def regex_from_formats(formats_array)
      formats_array.map {|x| "(#{x})"}
    end

    def all_month_name_regex(date_obj)
      formats = []

      day = date_obj.day
      day = "0?#{day}" if day < 10

      year = date_obj.strftime("%Y")
      year_short = date_obj.strftime("%y")

      month_name = date_obj.strftime("%B")
      month_name_short = date_obj.strftime("%b")

      month_str_regex_back = "([\s\/\|]*)(\\w*)"
      month_str_regex_front = "(\\w*)([\s\/\|]*)"
      month_regex = "#{month_str_regex_front}#{month_name}#{month_str_regex_back}"
      month_regex_short = "#{month_str_regex_front}#{month_name_short}#{month_str_regex_back}"

      str_delimeters = '-, /.'


      formats << "#{day}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{year}"
      formats << "#{day}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{year_short}"

      formats << "#{year}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{day}"
      formats << "#{year_short}[#{str_delimeters}]#{month_name}([\s\\|]*)(\\w*)[#{str_delimeters}]#{day}"


      formats << "#{month_regex}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year}"
      formats << "#{month_regex}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year_short}"

      formats << "#{month_regex}[#{str_delimeters}]#{year}[#{str_delimeters}]#{day}"
      formats << "#{month_regex}[#{str_delimeters}]#{year_short}[#{str_delimeters}]#{day}"

      formats << "#{day}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{year}"
      formats << "#{day}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{year_short}"

      formats << "#{year}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{day}"
      formats << "#{year_short}[#{str_delimeters}]#{month_name_short}([\s\\|]*)(\\w*)[#{str_delimeters}]#{day}"


      formats << "#{month_regex_short}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year}"
      formats << "#{month_regex_short}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year_short}"

      formats << "#{month_regex_short}[#{str_delimeters}]#{year}[#{str_delimeters}]#{day}"
      formats << "#{month_regex_short}[#{str_delimeters}]#{year_short}[#{str_delimeters}]#{day}"


      formats << "#{month_name} #{day}, #{year}"
      formats << "#{month_name_short} #{day}, #{year}"
      formats << "#{day}[#{str_delimeters}]*#{month_name_short.upcase}[#{str_delimeters}]*#{year}"

      return regex_from_formats(formats)
    end

  end
end