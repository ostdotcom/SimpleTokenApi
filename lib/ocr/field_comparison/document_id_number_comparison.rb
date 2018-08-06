module Ocr

  module FieldComparison

    class DocumentIdNumberComparison < Base

    # Initialize
    #
    # * Author: Aniket
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @return [Ocr::FieldComparison::DocumentIdNumberComparison]
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
    # @return [Integer]
    #
    def perform
      super
    end

    private

    #
    #
    # * Author: Aniket
    # * Date: 06/06/2018
    # * Reviewed By:
    #
    # @return [Integer]
    def compare
      # remove special characters from the document id and paragraph

      @match_string.gsub!(/[- \. \/]/, '')
      return 0 if @match_string.blank?

      @paragraph.gsub!(/[- \. \/]/, '')

      @paragraph.split("\n").each do |line|
        next if line.blank?
        start_index, current_index = 0, 0
        current_letter_matches = 0

        while (current_index < line.length)

          if (line[current_index].downcase == @match_string[current_letter_matches].downcase)
            start_index = current_index if current_letter_matches == 0
            current_letter_matches += 1
            return 100 if current_letter_matches == @match_string.length
          else
            start_index = start_index + 1
            current_index = start_index - 1
            current_letter_matches = 0
          end

          current_index += 1
        end

      end

      return 0
    end

    def similar_char_mapping
      {
          # 'o' => '0',
          # '0' => 'o',
          # '1' => 'i',
          # 'i' => '1'
      }
    end


    end
    end
end