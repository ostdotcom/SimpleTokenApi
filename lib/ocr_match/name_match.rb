module OcrMatch
  class NameMatch

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
      @safe_string = ""

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

      @safe_string = safe_characters(@words_array)

      return if @safe_string.blank?

      compare_passport_last_name(@safe_string, @match_string)
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

    # def compare_name
    #
    #   @match_string = safe_characters(@match_string)
    #   return if @match_string.blank?
    #
    #   match_percent = 0
    #
    #   @words_array.split("\n").each do |line|
    #     line = line.gsub(/ /, '')
    #     formatted_match_string = @match_string.gsub(/ /, '')
    #
    #     next if line.blank?
    #
    #     #
    #     # name = names[0][3..-1]
    #
    #     next if line.blank?
    #
    #     # AMAN: please check the logic
    #     match_percent = 100 if line.downcase.match(formatted_match_string.downcase)
    #
    #     puts "got #{formatted_match_string.downcase} in line : #{line.downcase}"
    #
    #     if match_percent < 100
    #
    #       formatted_line = line.sub(/[^p]*p</, '')
    #       names = formatted_line.split('<')
    #       names.uniq!
    #
    #       next if names.blank?
    #
    #       name = names[0]
    #
    #       next if name.blank?
    #
    #       match_percent = 100 if name.downcase.match(formatted_match_string.downcase)
    #
    #       puts "got #{formatted_match_string.downcase} in line : #{name.downcase}"
    #
    #     end
    #
    #     break if match_percent == 100
    #
    #   end
    #
    #   match_percent
    # end




    def compare_passport_last_name(paragraph, name)
      name = safe_characters(name)
      paragraph.split("\n").each do |line|
        line = line.gsub(/ /, '')
        next if line.blank? || !line.match(/p</)
        formatted_line = line.sub(/[^p]*p</, '')
        names = formatted_line.split('<')
        names.uniq!
        next if names.blank?
        last_name = names[0][3..-1]
        next if last_name.blank?
        return 100 if last_name.downcase == name.downcase
      end
      return 0
    end

  end
end


