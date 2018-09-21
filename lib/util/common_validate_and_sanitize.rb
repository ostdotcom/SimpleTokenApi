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
      true if Integer(object) rescue false
    end

  end

end
