module Ocr

  module FieldComparison

  class NameComparison < Base

    # @return [Ocr::FieldComparison::NameComparison]

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

      percent_match = 0

      @paragraph.split("\n").each do |line|
        next if line.blank?
        percent_match = 100 if line.match(/\b#{@match_string}\b/i)

        break if percent_match == 100
      end

      if percent_match < 100

        matched_words, total_count = check_name_by_split

        percent_match = 100 if total_count == matched_words.count
      end

      percent_match
    end


    def check_name_by_split

      matched_words, total_count = [], 0

      @match_string.split(" ").each do |word|
        total_count += 1
        word = word.downcase
        @paragraph.split("\n").each do |line|
          next if line.blank?

          if line.match(/\b#{word}\b/i)
            matched_words << word
            break
          else
            passport_words_array = passport_string(line)
            passport_words_array.each do |passport_word|

              if passport_word.match(/\b#{word}\b/i)
                matched_words << word
                break
              end
            end
          end
        end
      end

      return matched_words, total_count

    end


    def passport_string(line)

      line.match(/([A-Za-z]+<+)+/).to_s.split("<")

    end

  end
  end

end
