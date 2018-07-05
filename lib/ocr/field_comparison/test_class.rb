module Ocr

  module FieldComparison

  # Ocr::TestClass::FieldComparison.test
  class TestClass
    def self.test

      count = 0
      failure_array = []
      # "document_id_number_match_percent<100"
      # # "first_name_match_percent<100"
      # case_id:7300
      #
      VisionCompareText.all.each do |obj|
        puts obj.case_id

        next if obj.debug_data.blank? || obj.debug_data[:err].present? || obj.debug_data[:error_type].present?

        not_match_data = obj.debug_data[:not_match_data]
        word_array  = obj.debug_data[:words_array]

        first_name = not_match_data[:birthdate]

        puts "first_name :  #{first_name}"


        first_name_match_percent = OcrComparison::BirthdateComparison.new(word_array,first_name).perform

        puts "first_name_match_percent : #{first_name_match_percent}"

        count +=1 if first_name_match_percent > 0

      end

      puts "modified count : #{count}"


    end
  end
  end

end

