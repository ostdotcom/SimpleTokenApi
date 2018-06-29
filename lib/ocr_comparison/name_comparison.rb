module OcrComparison
  class NameComparison < Base

    # @return [OcrComparison::NameComparison.new()]

    private

    def compare

      percent_match = 0
      @match_string = safe_characters(@match_string)

      @safe_line_array.split("\n").each do |line|
        next if line.blank?
        percent_match = 100 if line.match(/\b#{@match_string}\b/i)

        break if percent_match == 100
      end

      if percent_match < 100
        matched_words, total_count = [], 0

        @match_string.split(" ").each do |word|
          total_count += 1
          @safe_line_array.split("\n").each do |line|
            next if line.blank?
            if line.match(/\b#{word}\b/i)
              matched_words << word
            end
          end
        end

        percent_match = 100 if total_count == matched_words.count
      end

      percent_match
    end

  end
end
