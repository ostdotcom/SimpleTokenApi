namespace :vision_poc do

  # rake vision_poc:compare_document_image_text RAILS_ENV=development

  task :compare_document_image_text => :environment do

    UserKycDetail.select('id, user_id, user_extended_detail_id')
        .where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id)
        .find_in_batches(batch_size: 100) do |batches|

      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        ued = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)

        kyc_salt_d = r.data[:plaintext]

        local_cipher_obj = LocalCipher.new(kyc_salt_d)

        document_file = nil
        document_file = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext]

        resp = Google::VisionService.new.api_call_detect_text(document_file)
        request_time = resp.data[:request_time]
        puts "Google Vision Request Time: #{resp.data[:request_time]} milliseconds."

        insert_row = {case_id: user_kyc_detail.id, request_time: request_time || 0}

        comparison_columns = {first_name: 0, last_name: 0, birthdate: 0,
                              document_id_number: 0, nationality: 0}


        debug_data = {}
        date_of_birth = nil
        if resp.success?
          words_array = resp.data[:words_array]
          debug_data = {words_array: words_array, not_match_data: {}}

          words_hash = construct_lookup_data(words_array)
          all_dates = get_dates(words_array)


          if words_hash.present?
            comparison_columns.each do |key, _|
              column_name = key.to_sym

              db_value = nil
              if [:first_name, :last_name].include?(column_name)
                db_value = ued[column_name]
              else
                db_value = local_cipher_obj.decrypt(ued[column_name]).data[:plaintext] if ued[column_name].present?
              end

              if column_name != :birthdate
                comparison_columns[column_name] = 100 if words_hash[db_value.downcase] == 1
              else
                date_of_birth = Date.parse(db_value, "%Y-%m-%d")
                comparison_columns[column_name] = 100 if all_dates.include?(date_of_birth)
              end

              insert_row["#{key}_match_percent".to_sym] = comparison_columns[column_name]
              debug_data[:not_match_data][column_name] = db_value if comparison_columns[column_name] == 0
            end
          end
        else
          debug_data = resp.data[:debug_data]
        end

        insert_row.merge!({debug_data: debug_data, date_of_birth: date_of_birth, orientation: resp.data[:orientation]})
        puts insert_row
        VisionCompareText.create!(insert_row)
      end
    end

  end

  def construct_lookup_data(paragraph)
    words_hash = {}
    paragraph.split(%r{[\s\n]}).each do |word|
      next if word.blank?
      words_hash[word.downcase] = 1
    end
    words_hash
  end

  def get_dates(paragraph)
    delimeters = '\/\-\. '
    date_regex = /\d{1,4}[#{delimeters}]\d{1,2}[#{delimeters}]\d{2,4}/
    dates = []
    paragraph.split("\n").each do |line|
      next if line.blank?
      date_str_array = line.scan(date_regex)
      date_str_array.each do |date_str|
        dates += get_valid_dates(date_str)
      end
    end
    dates.uniq
  end

  def date_delimeters
    ['/', '-', '.']
  end

  def all_date_formats
    @all_date_formats ||= begin
      formats = []
      date_delimeters.each do |delimeter|
        formats += ["%y#{delimeter}%m#{delimeter}%d", "%d#{delimeter}%m#{delimeter}%y", "%m#{delimeter}%d#{delimeter}%y"]
      end
      formats
    end
  end

  def get_valid_dates(date_str)
    date_objects = []
    all_date_formats.each do |format|
      date = Date.parse(date_str, format) rescue nil
      date_objects << date if date.present?
    end
    date_objects
  end

  # check date similarity
  #
  # * Author: Sachin
  # * Date: 19/06/2018
  # * Reviewed By:
  #
  # @return [Boolean] returns flag
  #
  # def date_matches?(actual_date, given_date)
  #
  #   # parsed_given_date = Date.parse(given_date) rescue nil
  #   #
  #   # unless parsed_given_date.nil?
  #   #   return actual_date == parsed_given_date.to_s
  #   # end
  #
  #   actual_date_object = Date.parse(actual_date)
  #   actual_day = actual_date_object.day.to_s
  #   actual_month_number = actual_date_object.month.to_s
  #   actual_month_string = actual_date_object.strftime('%b').downcase
  #   actual_month_string_full = actual_date_object.strftime('%B').downcase
  #   actual_year = actual_date_object.year.to_s
  #
  #   # puts actual_day, actual_month_number, actual_month_string, actual_month_string_full, actual_year
  #
  #   date_hasp_map = {}
  #   given_date.split(%r{[.,\\ \/-]}).map {|x|
  #     if x.to_i != 0
  #       x = x.to_i.to_s
  #     end
  #     date_hasp_map[x.downcase] = 1}
  #
  #   puts date_hasp_map
  #
  #   date_hasp_map[actual_day].present? &&
  #       (date_hasp_map[actual_month_number].present? || date_hasp_map[actual_month_string].present? || date_hasp_map[actual_month_string_full].present?) &&
  #       date_hasp_map[actual_year].present?
  #
  # end

  # def date_matches?(src, des)
  #   parsed_date = Date.parse(des) rescue nil
  #   return false if parsed_date.nil?
  #
  #   src == parsed_date.to_s
  # rescue => e
  #   false
  # end

end