module Ocr

  module FieldComparison

    class NameComparison < Base

      # Initialize
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Ocr::FieldComparison::NameComparison]
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
      def perform
        super
      end

      private

      # compare if name is present in the document
      # checks  full name as words match in a line or
      # words split by "{<}, {\s}" in a machine readable passport line has all the words in a name
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Integer]
      def compare

        @paragraph.split("\n").each do |line|
          next if line.blank?
          # full word match
          escaped_regex_string = Util::CommonValidator.escape_regex(@match_string)
          return 100 if line.match(/\b#{escaped_regex_string}\b/i)
          # machine readable passport line has all  word of a name
          return 100 if passport_name_matched?(line)
        end


        # matched_words, total_word_count = check_name_by_split
        # return 100 if total_word_count == matched_words.count
        0
      end

      # words split by "{<}, {\s}" in a machine readable passport line has all the words in a name
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def passport_name_matched?(line)


        # remove any extra characters before the Machine-readable_passport line
        formatted_line = sanitize_machine_readable_passport_line(line)

        return false if formatted_line.blank?

        # passport has the name starting from 6th character
        # https://en.wikipedia.org/wiki/Machine-readable_passport
        # space is also used as a separator in case if api inserts a space in between
        #
        all_words = formatted_line[5..-1].to_s.split("<")
        all_words_in_name = @match_string.split(" ")

        return true if (all_words_in_name - all_words).blank?
        return false
      end


      # def check_name_by_split
      #   matched_words, total_word_count = [], 0
      #   @match_string.split(" ").each do |word|
      #     total_word_count += 1
      #     word = word.downcase
      #
      #     @paragraph.split("\n").each do |line|
      #       next if line.blank?
      #
      #       if line.match(/\b#{word}\b/i)
      #         matched_words << word
      #         break
      #       end
      #     end
      #
      #   end
      #
      #   return matched_words, total_word_count
      # end

    end
  end

end
