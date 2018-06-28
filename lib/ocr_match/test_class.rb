module OcrMatch
  # OcrMatch::TestClass.test
  class TestClass
    def self.test

      count = 0
      VisionCompareText.where("first_name_match_percent<100").limit(10).each do |obj|
        puts obj.case_id

        next if obj.debug_data.blank? || obj.debug_data[:err].present? || obj.debug_data[:error_type].present?

        not_match_data = obj.debug_data[:not_match_data]
        word_array  = obj.debug_data[:words_array]

        first_name = not_match_data[:first_name]

        puts "first_name :  #{first_name}"


        first_name_match_percent = OcrMatch::NameMatch.new(word_array,first_name).perform


        count +=1 if first_name_match_percent == 100
        puts "first_name_match_percent : #{first_name_match_percent}"
      end

      puts "modified count : #{count}"

    end
  end
end

