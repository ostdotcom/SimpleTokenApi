class VisionCompareText < EstablishImageProcessingPocDbConnection

  serialize :debug_data, Hash

  # PASSPORT_DETAILS_REGEX = /[0-9A-Z]+<*(\d|O)[A-Z]{3}\d{7}[A-Z]\d{7}/
  PASSPORT_DETAILS_REGEX = /[A-Z]{3}\d{7}[A-Z]\d{7}/

  PASSPORT_NAME_REGEX = /([A-Z]+<+)+/

  @total = 0
  @pn = 0

  def self.a
    # where("document_id_number_match_percent < 1000 ")

    pt = 0

    VisionCompareText.all.each do |obj|
      debug_data = eval(JSON.parse(obj.debug_data.to_json)) rescue obj.debug_data
      next if debug_data.blank? || debug_data[:err].present? || debug_data[:error_type].present?
      obj.debug_data = debug_data

      # puts obj.case_id


      paragraph = debug_data[:words_array]
      safe_paragraph = VisionCompareText.safe_characters(paragraph)
      passport_check_string = safe_paragraph.delete(' ')

      # nationality_resp = VisionCompareText.check_for_nationality(passport_check_string, nationality)

      passport_detected = VisionCompareText.check_for_passport(safe_paragraph)
      if passport_detected
        pt+=1
      end
      next

      # puts passport_detected
      #

      not_match_data = debug_data[:not_match_data]

      not_match_data.each do |key, val|
        column_name = key.to_s
        val = val.to_s.downcase
        match_percent = 0

        if [:first_name, :last_name].include?(column_name.to_sym)
          match_percent = VisionCompareText.check_for_name(passport_check_string, val)
        end

        if [:document_id_number].include?(column_name.to_sym)
          match_percent = VisionCompareText.compare_document_id(safe_paragraph, val)
        end

        if [:nationality].include?(column_name.to_sym)
          match_percent = VisionCompareText.check_for_nationality(safe_paragraph, val)
        end

        if [:birthdate].include?(column_name.to_sym)
          val = Date.strptime(val, "%Y-%m-%d")
          match_percent = VisionCompareText.check_for_date_of_birth(safe_paragraph, val)
        end


        not_match_data.delete(column_name) if match_percent.to_i == 100
        obj["#{column_name}_match_percent"] = match_percent

      end
      #
      obj.save! if obj.changed?
    end
    return pt
  end

  def self.check_for_passport(detected_text)
    passport_check_string = detected_text.delete(' ')
    if passport_check_string =~ PASSPORT_DETAILS_REGEX && passport_check_string =~ PASSPORT_NAME_REGEX
      return true
    else
      return false
    end
  end

  def self.check_for_nationality(passport_check_string, nationality)
    if !nationality.nil? && passport_check_string =~ PASSPORT_DETAILS_REGEX
      code = passport_check_string.match(PASSPORT_DETAILS_REGEX).to_s[0,3].to_s
      obj = ISO3166::Country.find_country_by_alpha3(code)
      # puts "code " + code
      # puts "nationality : from code " + obj.nationality
      # puts "given nationality " +nationality
      if !obj.nil? && obj.nationality.to_s.downcase == nationality
        return 100*1.0
      end
    end
    return 0.0
  end

  def self.check_for_date_of_birth(passport_check_string, dob)
    if passport_check_string =~ PASSPORT_DETAILS_REGEX
      # puts passport_check_string.match(PASSPORT_DETAILS_REGEX).to_s[3,6].to_s
      # puts VisionCompareText.get_date_passport_format(dob)
      if passport_check_string.match(PASSPORT_DETAILS_REGEX).to_s[3,6].to_s == VisionCompareText.get_date_passport_format(dob)
        return 100*1.0
      end
    end
    return 0.0
  end

  def self.check_for_name(passport_check_string, first_name)
    if passport_check_string =~ PASSPORT_NAME_REGEX
      hash = {}
      passport_check_string.match(PASSPORT_NAME_REGEX).to_s[5,999].to_s.split('<').map {|x|
        hash[x.downcase] = 1 unless x.blank?
      }
      unless first_name.nil?
        puts "Name :" + first_name
        first_name_array = first_name.split(' ')
        name_size = first_name_array.size
        matched = 0
        first_name_array.each do |subName|
          unless hash[subName].nil?
            matched+=1
          end
        end
        return (matched*1.0/name_size)*100
      end
    end
    return 0*1.0
  end


  def self.get_date_passport_format(given_date)
    actual_date_object = Date.parse(given_date)
    actual_date_object.strftime('%y') + actual_date_object.strftime('%m') + actual_date_object.strftime('%d')
  end

  def self.compare_name(paragraph, name)
    name = safe_characters(name)
    paragraph.split("\n").each do |line|
      next if line.blank?
      return 100 if line.match(/\b#{name}\b/i)
    end

    matched_words, total_count = [], 0

    name.split(" ").each do |word|
      total_count += 1
      paragraph.split("\n").each do |line|
        next if line.blank?
        if line.match(/\b#{word}\b/i)
          matched_words << word
        end
      end
    end


    # 888 some letters in the name changes in response (aws as well)
    # give some percent??

    matched_words.uniq!

    return ((matched_words.length * 90.0) / total_count)
  end

  def self.compare_document_id(paragraph, doc_id)
    doc_id.gsub!(/[- \.]/, '')
    doc_id = safe_characters(doc_id)

    puts "match document id"

    paragraph.split("\n").each do |line|
      next if line.blank?

      start_index, current_index = 0, 0
      current_letter_matches = 0

      while (current_index < line.length)

        next if ["-", " ", "."].include?(line[current_index])

        if line[current_index] == doc_id[current_letter_matches]
          start_index = current_index if current_letter_matches == 0
          current_letter_matches += 1
        else
          current_index = start_index + 1
          current_letter_matches = 0
        end

        current_index += 1
      end


      return 100 if current_letter_matches == doc_id.length
    end

    matched_words, total_count = [], 0

    name.split(" ").each do |word|
      total_count += 1
      paragraph.split("\n").each do |line|
        next if line.blank?
        if line.match(/\b#{word}\b/i)
          matched_words << word
        end
      end
    end


    # 888 some letters in the name changes in response (aws as well)
    # give some percent??

    matched_words.uniq!

    return ((matched_words.length * 90.0) / total_count)
  end


  def self.safe_characters(paragraph)
    safe_paragraph = ""
    paragraph.each_char do |letter|
      safe_letter = letter.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').to_s
      safe_letter = letter.parameterize if safe_letter.blank?
      safe_paragraph += safe_letter.present? ? safe_letter : letter
    end
    safe_paragraph
  end


end