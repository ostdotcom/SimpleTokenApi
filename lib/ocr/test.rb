module Ocr
  # Ocr::Test.test
  class Test
    def self.test
      count = 0
      faliure_array = []
      # 'nationality_match_percent < 100'
      # where(case_id:9827)
      VisionCompareText.all.each do |obj|
        puts obj.case_id
        debug_data = eval(JSON.parse(obj.debug_data.to_json)) rescue obj.debug_data
        obj.debug_data = debug_data
        next if obj.debug_data.blank? || obj.debug_data[:err].present? || obj.debug_data[:error_type].present?
        not_match_data = obj.debug_data[:not_match_data]
        word_array  = obj.debug_data[:words_array]
        first_name = not_match_data[:nationality]
        puts "first_name :  #{first_name}"
        param = {'paragraph':word_array,'match_string':first_name}
        first_name_match_percent = Ocr::FieldComparison::NationalityComparison.new(param).perform
        count +=1 if first_name_match_percent > 0
        # obj.nationality_match_percent = first_name_match_percent
        # obj.save! if first_name_match_percent > 0
        faliure_array << obj.case_id if first_name_match_percent == 0
        puts "first_name_match_percent : #{first_name_match_percent}"
      end
      puts "faliure_array : #{faliure_array}"
      puts "faliure_array_size : #{faliure_array.size}"
      puts "modified count : #{count}"
    end
  end
end