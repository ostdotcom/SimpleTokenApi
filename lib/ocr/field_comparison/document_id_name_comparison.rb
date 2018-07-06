module Ocr

  module FieldComparison

    class DocumentIdNameComparison < Base

    # @return [Ocr::FieldComparison::DocumentIdNameComparison.new()]

    # Initialize
    # * Author: Aniket
    #* Date: 06/06/2018
    #* Reviewed By:
    #
    def initialize(params)
      super

    end

    # Perform
    # * Author: Aniket
    #* Date: 06/06/2018
    #* Reviewed By:
    #
    def perform
      super
    end

    private

    def compare
      @match_string.gsub!(/[- \. \/]/, '')

      @paragraph.split("\n").each do |line|
        next if line.blank?
        start_index, current_index = 0, 0
        current_letter_matches = 0

        while (current_index < line.length)

          if ["-", " ", ".", "/"].include?(line[current_index])
            current_index += 1
            next
          end

          if (line[current_index].downcase == @match_string[current_letter_matches].downcase) ||
              (similar_char_mapping[line[current_index].downcase] == @match_string[current_letter_matches].downcase)
            start_index = current_index if current_letter_matches == 0
            current_letter_matches += 1
            return 100 if current_letter_matches == @match_string.length
          else
            if current_letter_matches > 3
              # concern_case_ids << case_id
            end

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