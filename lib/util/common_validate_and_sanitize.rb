module Util

  class CommonValidateAndSanitize

    # Util::CommonValidateAndSanitize

    # for integer array
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Boolean] returns a boolean
    # modifies objects too
    #
    def self.integer_array!(objects)
      return false unless objects.is_a?(Array)

      objects.each_with_index do |o, i|
        return false unless CommonValidator.is_numeric?(o)

        objects[i] = o.to_i
      end

      return true
    end

    # get safe paragraph
    #
    # * Author: Aniket
    # * Date: 05/07/2018
    # * Reviewed By:
    #
    # @return [string] Returns paragraph with characters in utf-8
    #
    def self.safe_paragraph(paragraph)
      return paragraph if paragraph.blank?
      safe_paragraph = ""
      paragraph.each_char do |letter|
        safe_letter = letter.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '')
        safe_letter = letter.parameterize if safe_letter.blank?
        safe_paragraph += safe_letter.present? ? safe_letter.downcase.to_s : letter.downcase.to_s
      end
      safe_paragraph
    end

    # convert words separated by space to allow multiple or 0 spaces in between words
    #
    # * Author: Aniket
    # * Date: 05/07/2018
    # * Reviewed By:
    #
    # @return [string] Returns regex separated by space to allow multiple or 0 spaces in between word
    #
    def self.get_words_regex_for_multi_space_support(word)
      return word if word.blank?
      return word.gsub(/ +/, ' *')
    end

    # check whether give object is integer or not
    #
    # * Author: Aniket
    # * Date: 20/09/2018
    # * Reviewed By:
    #
    #  @return [Boolean] return true if object is integer
    #
    def self.is_integer?(object)
      return false if object.is_a?(Float)
      true if Integer(object) rescue false
    end

    # check whether give object is String or not
    #
    # * Author: Aniket
    # * Date: 20/09/2018
    # * Reviewed By:
    #
    #  @return [Boolean] return true if object is String
    #
    def self.is_string?(object)
      object.is_a?(String)
    end

    # check whether give object is integer and >=1
    #
    # * Author: Aniket
    # * Date: 20/09/2018
    # * Reviewed By:
    #
    #  @return [Boolean] return true if object is integer
    #
    def self.is_positive_integer?(object)
      res = is_integer?(object)
      res = false if res && object.to_i <= 0
      res
    end

    # check whether give object is Hash or not
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    #  @return [Boolean] return true if object is Hash
    #
    def self.is_hash?(object)
      object.is_a?(Hash) || object.is_a?(ActionController::Parameters)
    end

    # check whether give object is Array or not
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @param kind(optional): value should be either integer or hash or boolean
    #
    #  @return [Boolean] return true if object is Array
    #
    def self.is_array?(object, data_kind = nil)
      object.is_a?(Array)

      is_valid_data_kind = true
      if data_kind
        object.each do |ele|
          case data_kind
            when 'integer'
              is_valid_data_kind = self.is_integer?(ele)
            when 'hash'
              is_valid_data_kind = self.is_hash?(ele)
            when 'boolean'
              is_valid_data_kind = self.is_boolean?(ele)
            else
              puts 'invalid data_kind passed.'
              return is_valid_data_kind
          end
          break unless is_valid_data_kind
        end
      end
      puts "here"
      is_valid_data_kind
    end

    def self.is_boolean?(object)
      object = true if object == 'true' || object == 1
      object = false if object == 'false' || object == 0

      object.is_a?(TrueClass) || object.is_a?(FalseClass)
    end

  end

end
