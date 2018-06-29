module OcrComparison
  class Base

    # Initialize
    # @params [Array] words_array(mandatory)
    # @params [String] match_string(mandatory)
    #
    # Sets @words_array, @match_string
    #
    # @return [OcrComparison::Base.new()]
    #
    #* Author: Aniket
    #* Date: 28/06/2018
    #* Reviewed By:
    #
    def initialize(line_array, match_string)

      @line_array = line_array
      @match_string = match_string
      @safe_line_array = safe_characters(@line_array)

    end

    def perform
      return 0 if @safe_line_array.blank?
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

    end

  end
end