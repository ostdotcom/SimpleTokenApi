class VisionCompareText < EstablishImageProcessingPocDbConnection

  serialize :debug_data, Hash


  def self.a_p

    count = 0
    concerned_case_ids , unmatched_ids= [], []

    VisionCompareText.where("debug_data like '%p<%<<<%' ").where('last_name_match_percent < 100').all.each do |obj|
      puts obj.case_id
      debug_data = eval(JSON.parse(obj.debug_data.to_json)) rescue obj.debug_data
      next if debug_data.blank? || debug_data[:err].present? || debug_data[:error_type].present?
      obj.debug_data = debug_data

      paragraph = debug_data[:words_array]
      safe_paragraph = VisionCompareText.safe_characters(paragraph)
      not_match_data = debug_data[:not_match_data]

      not_match_data.each do |key, val|
        column_name = key.to_s


        # if [:first_name, :last_name].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_passport_first_name(safe_paragraph, val)
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent
        # end

        if [:last_name].include?(column_name.to_sym)
          concerned_case_ids << obj.case_id
          match_percent = VisionCompareText.compare_passport_last_name(safe_paragraph, val)
          if match_percent == 100
            not_match_data.delete(column_name)
            count += 1
          else
            unmatched_ids << obj.case_id
          end
          obj["#{column_name}_match_percent"] = match_percent
        end
        #
        # if [:document_id_number].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_document_id(safe_paragraph, val, obj.case_id, concern_case_ids)
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent
        # end

        # if [:birthdate].include?(column_name.to_sym)
        #   date_of_birth = Date.strptime(val, "%Y-%m-%d")
        #   all_possible_date_number_regex_array = VisionCompareText.all_possible_date_number_regex(date_of_birth)
        #
        #   if safe_paragraph.match(/#{all_possible_date_number_regex_array.join("|")}/i)
        #     not_match_data.delete(column_name)
        #     obj["#{column_name}_match_percent"] = 100
        #   else
        #     all_month_name_regex_array = VisionCompareText.all_month_name_regex(date_of_birth)
        #     if safe_paragraph.match(/#{all_month_name_regex_array.join("|")}/i)
        #       not_match_data.delete(column_name)
        #       obj["#{column_name}_match_percent"] = 100
        #     end
        #   end
        #
        # end

        # if [:nationality].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_nationality(safe_paragraph, val)
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent
        # end

      end

      if obj.changed?
        # obj.save!
        # count += 1
      end
    end
    return concerned_case_ids, count, concerned_case_ids.length, unmatched_ids

  end

  def self.compare_passport_last_name(paragraph, name)
    name = safe_characters(name)
    paragraph.split("\n").each do |line|
      line = line.gsub(/ /, '')
      next if line.blank? || !line.match(/p</)
      formatted_line = line.sub(/[^p]*p</, '')
      names = formatted_line.split('<')
      names.uniq!
      next if names.blank?
      last_name = names[0][3..-1]
      next if last_name.blank?
      return 100 if last_name.downcase == name.downcase
    end
    return 0
  end

  # 177
  #
  def self.a(concern_case_ids = [])
    #.where(case_id: 8982)

    count = 0
    VisionCompareText.where("birthdate_match_percent < 100").all.each do |obj|
      puts obj.case_id
      debug_data = eval(JSON.parse(obj.debug_data.to_json)) rescue obj.debug_data
      next if debug_data.blank? || debug_data[:err].present? || debug_data[:error_type].present?
      obj.debug_data = debug_data

      paragraph = debug_data[:words_array]
      safe_paragraph = VisionCompareText.safe_characters(paragraph)
      not_match_data = debug_data[:not_match_data]
      not_match_data[:birthdate.to_s] ||= obj.date_of_birth

      not_match_data.each do |key, val|
        column_name = key.to_s

        # if [:first_name, :last_name].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_name(safe_paragraph, val)
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent
        # end
        #
        # if [:document_id_number].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_document_id(safe_paragraph, val, obj.case_id, concern_case_ids)
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent
        # end

        if [:birthdate].include?(column_name.to_sym)
          date_of_birth = Date.strptime(val, "%Y-%m-%d")
          all_possible_date_number_regex_array = VisionCompareText.all_possible_date_number_regex(date_of_birth)

          if safe_paragraph.match(/#{all_possible_date_number_regex_array.join("|")}/i)
            not_match_data.delete(column_name)
            obj["#{column_name}_match_percent"] = 100
          else
            all_month_name_regex_array = VisionCompareText.all_month_name_regex(date_of_birth)
            if safe_paragraph.match(/#{all_month_name_regex_array.join("|")}/i)
              not_match_data.delete(column_name)
              obj["#{column_name}_match_percent"] = 100
            end
          end

          if obj["#{column_name}_match_percent"] < 100
            date_of_birth = Date.strptime(val, "%Y-%m-%d").strftime("%y%m%d")
            obj["#{column_name}_match_percent"] = 100 if safe_paragraph.match(date_of_birth)
          end

        end

        # if [:nationality].include?(column_name.to_sym)
        #   match_percent = VisionCompareText.compare_nationality(safe_paragraph, val) || 0
        #   not_match_data.delete(column_name) if match_percent == 100
        #   obj["#{column_name}_match_percent"] = match_percent if match_percent == 100
        # end

      end

      if obj.changed?
        obj.save!
        count += 1
      end
    end

    puts count
    # return false
    return concern_case_ids
  end

  def self.compare_nationality(paragraph, nationality)
    return 100 if paragraph.match(/#{nationality}/i)

    country = nationalities_mapping[nationality.downcase]
    return 100 if country.present? and paragraph.match(/#{country}/i)

    if ['american', 'U.S. TERRITORY'.downcase].include?(nationality.downcase)
      usa_states.each{|uss| return 100 if paragraph.match(/#{uss}/i)}
    end
  end

  def self.all_possible_date_number_regex(date_obj)
    formats = []
    month = date_obj.month
    month = "0?#{month}" if month < 10

    day = date_obj.day
    day = "0?#{day}" if day < 10

    year = date_obj.strftime("%Y")
    year_short = date_obj.strftime("%y")

    delimeters = ['/', '-', '.', ' ', ',', '']

    delimeters.each do |delimeter|
      delimeter = "\s*#{delimeter}\s*"
      formats << "#{day}#{delimeter}#{month}#{delimeter}#{year}"
      formats << "#{year}#{delimeter}#{month}#{delimeter}#{day}"
      formats << "#{month}#{delimeter}#{day}#{delimeter}#{year}"
      formats << "#{month}#{delimeter}#{year}#{delimeter}#{day}"

      formats << "#{day}#{delimeter}#{month}#{delimeter}#{year_short}"
      formats << "#{year_short}#{delimeter}#{month}#{delimeter}#{day}"
      formats << "#{month}#{delimeter}#{day}#{delimeter}#{year_short}"
      formats << "#{month}#{delimeter}#{year_short}#{delimeter}#{day}"
    end

    formats << "#{day}.#{month} #{year}"
    formats << "#{day}#{month}#{year}"
    formats << "#{day}:#{month}-#{year}"

    # formats << "#{year}#{month}#{day}"
    # formats << "#{month}#{day}#{year}"
    formats << "#{month}/#{day} #{year}"
    formats << "#{day} #{month}-#{year}"
    formats << "#{day}#{month}/#{year}"

    return VisionCompareText.regex_from_formats(formats)
  end

  def self.regex_from_formats(formats_array)
    formats_array.map {|x| "(#{x})"}
  end

  def self.all_month_name_regex(date_obj)
    formats = []

    day = date_obj.day
    day = "0?#{day}" if day < 10

    year = date_obj.strftime("%Y")
    year_short = date_obj.strftime("%y")

    month_name = date_obj.strftime("%B")
    month_name_short = date_obj.strftime("%b")

    month_str_regex_back = "([\s\/\|]*)(\\w*)"
    month_str_regex_front = "(\\w*)([\s\/\|]*)"
    month_regex = "#{month_str_regex_front}#{month_name}#{month_str_regex_back}"
    month_regex_short = "#{month_str_regex_front}#{month_name_short}#{month_str_regex_back}"

    str_delimeters = '-, /.'


    formats << "#{day}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{year}"
    formats << "#{day}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{year_short}"

    formats << "#{year}[#{str_delimeters}]#{month_regex}[#{str_delimeters}]#{day}"
    formats << "#{year_short}[#{str_delimeters}]#{month_name}([\s\\|]*)(\\w*)[#{str_delimeters}]#{day}"


    formats << "#{month_regex}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year}"
    formats << "#{month_regex}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year_short}"

    formats << "#{month_regex}[#{str_delimeters}]#{year}[#{str_delimeters}]#{day}"
    formats << "#{month_regex}[#{str_delimeters}]#{year_short}[#{str_delimeters}]#{day}"

    formats << "#{day}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{year}"
    formats << "#{day}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{year_short}"

    formats << "#{year}[#{str_delimeters}]#{month_regex_short}[#{str_delimeters}]#{day}"
    formats << "#{year_short}[#{str_delimeters}]#{month_name_short}([\s\\|]*)(\\w*)[#{str_delimeters}]#{day}"


    formats << "#{month_regex_short}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year}"
    formats << "#{month_regex_short}[#{str_delimeters}]#{day}[#{str_delimeters}]#{year_short}"

    formats << "#{month_regex_short}[#{str_delimeters}]#{year}[#{str_delimeters}]#{day}"
    formats << "#{month_regex_short}[#{str_delimeters}]#{year_short}[#{str_delimeters}]#{day}"


    formats << "#{month_name} #{day}, #{year}"
    formats << "#{month_name_short} #{day}, #{year}"
    # formats << "#{day} #{month_name_short}, #{year}"
    # formats << "#{day} #{month_name_short}. #{year}"
    # formats << "#{day}#{month_name_short.upcase} #{year}"
    # formats << "#{day} #{month_name_short.upcase}#{year}"
    # formats << "#{day} #{month_name_short.upcase} #{year}"
    # formats << "#{day}#{month_name_short.upcase} #{year}"
    formats << "#{day}[#{str_delimeters}]*#{month_name_short.upcase}[#{str_delimeters}]*#{year}"

    return VisionCompareText.regex_from_formats(formats)
  end


  def self.get_dates(paragraph)
    delimeters = '\/\-\. '
    date_regex = /\d{1,4}[#{delimeters}]\d{1,2}[#{delimeters}]\d{1,4}/i

    str_delimeters = '\/\-, '
    date_regex1 = /\w{3,9}[#{str_delimeters}]\d{1,2}[#{str_delimeters}]\d{2,4}/i
    date_regex2 = /\d{1,4}[#{str_delimeters}]\w{3,9}([\s\\]*)(\w*)[#{str_delimeters}]\d{1,4}/i

    dates = []
    paragraph.split("\n").each do |line|
      next if line.blank?
      date_str_array = []
      date_str_array = line.scan(date_regex1)
      date_str_array += line.scan(date_regex2)
      date_str_array += line.scan(date_regex)
      date_str_array.each do |date_str|
        dates += VisionCompareText.get_valid_dates(date_str)
      end
    end
    dates.uniq
  end

  def self.date_delimeters
    ['/', '-', '.', ' ']
  end

  def self.all_date_formats
    @all_date_formats ||= begin
      formats = []
      VisionCompareText.date_delimeters.each do |delimeter|
        formats += ["%y#{delimeter}%m#{delimeter}%d", "%d#{delimeter}%m#{delimeter}%y", "%m#{delimeter}%d#{delimeter}%y"]
        formats += ["%Y#{delimeter}%m#{delimeter}%d", "%d#{delimeter}%m#{delimeter}%Y", "%m#{delimeter}%d#{delimeter}%Y"]
      end
      formats
    end
  end

  def self.get_valid_dates(date_str)
    date_objects = []
    VisionCompareText.all_date_formats.each do |format|
      date = Date.strptime(date_str, format) rescue nil
      date_objects << date if date.present?
    end
    date_objects
  end


  def self.compare_document_id(paragraph, doc_id, case_id, concern_case_ids)
    doc_id.gsub!(/[- \. \/]/, '')
    doc_id = safe_characters(doc_id)

    paragraph.split("\n").each do |line|
      next if line.blank?
      start_index, current_index = 0, 0
      current_letter_matches = 0

      while (current_index < line.length)

        if ["-", " ", ".", "/"].include?(line[current_index])
          current_index += 1
          next
        end

        if (line[current_index].downcase == doc_id[current_letter_matches].downcase) ||
            (VisionCompareText.similar_char_mapping[line[current_index].downcase] == doc_id[current_letter_matches].downcase)
          start_index = current_index if current_letter_matches == 0
          current_letter_matches += 1
          return 100 if current_letter_matches == doc_id.length
        else
          if current_letter_matches > 3
            concern_case_ids << case_id
            puts "case_id-#{case_id}"
            puts "line-#{line}"
            puts "doc_id-#{doc_id}"
            puts "current_letter_matches-#{current_letter_matches}"
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


  def self.similar_char_mapping
    {
        'o' => '0',
        '0' => 'o',
        '1' => 'i',
        'i' => '1'
        # '/' => 'i',
        # 'i' => '/',
        # '/' => '1',
        # '1' => '/',
        # '4' => 'g',
        # 'g' => '4',
        # 'g' => '9',
        # '9' => 'g',
        # 'b' => '8',
        # '8' => 'b',
    }
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


  def self.safe_characters(paragraph)
    safe_paragraph = ""
    paragraph.each_char do |letter|
      safe_letter = letter.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
      safe_letter = letter.parameterize if safe_letter.blank?
      safe_paragraph += safe_letter.present? ? safe_letter : letter
    end
    safe_paragraph
  end

  def self.nationalities_mapping

    @nationality_map ||= {}
    if @nationality_map.blank?
      file = File.open("#{Rails.root}/country_nationality.csv", "rb")
      file.each do |row|
        sp = row.gsub("\r\n", "").split(",")
        @nationality_map[sp[1].downcase] = sp[0]
      end
    end

    return @nationality_map

  end

  def self.usa_states
    return ['USA','United States Minor Outlying Islands','United States of America',
            'Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida',
            'Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland',
            'Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana Nebraska','Nevada','New Hampshire',
            'New Jersey','New Mexico','New York','Dakota','Ohio','Oklahoma','Oregon',
            'Carolina','Tennessee','Texas','Utah','Vermont','Virginia',
            'Washington','West Virginia','Wisconsin','Wyoming','CAROLINA', 'Pennsylvania', 'Rhode Island']
  end


end