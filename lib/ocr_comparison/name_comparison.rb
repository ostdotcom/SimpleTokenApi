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

        matched_words, total_count = check_name_by_split

        puts "matched_words : #{matched_words}"
        percent_match = 100 if total_count == matched_words.count
      end

      percent_match
    end


    def check_name_by_split

      matched_words, total_count = [], 0

      @match_string.split(" ").each do |word|
        total_count += 1
        word = word.downcase
        @safe_line_array.split("\n").each do |line|
          next if line.blank?

          if line.match(/\b#{word}\b/i)
            puts "word #{word} matches in line : #{line}"
            matched_words << word
            break
          else
            passport_words_array = passport_string(line)
            passport_words_array.each do |passport_word|
              puts "inside passport_string : #{line}"

              if passport_word.match(/\b#{word}\b/i)
                puts "got word from passport : #{passport_word}"
                matched_words << word
                break
              end
            end
          end
        end
      end

      puts "matched_words : #{matched_words} and total_count : #{total_count}"
      return matched_words, total_count

    end


    def passport_string(line)

      line.match(/([A-Za-z]+<+)+/).to_s.split("<")

    end

  end
end
