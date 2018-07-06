module Ocr

  class CompareDocument

    include ::Util::ResultHelper

    # Initialize
    # @params [String] paragraph (mandatory) - paragraph
    # @params [Hash] document_details (mandatory) - details of user
    # @params [Array] dimensions (optional) - dimensions of words
    #
    # Sets @paragraph, @dimensions, @document_details, @rotation_angle, @comparison_percent, @result_hash
    #
    # @return [Ocr::CompareDocument]
    #
    #* Author: Aniket/Tejas
    #* Date: 04/07/2018
    #* Reviewed By:
    #

    def initialize(params)
      @paragraph = params[:paragraph].to_s
      @dimensions = params[:dimensions]
      @document_details = params[:document_details]

      @result_hash = {
          document_details: @document_details
      }

      @comparison_percent = {}
      @rotation_angle = nil

    end

    def perform
      @safe_paragraph = safe_characters(@paragraph)

      compare_first_name

      compare_last_name

      compare_birthdate

      compare_document_id

      get_orientation

      success_with_data(success_response_data)
    end

    private

    # get safe characters
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # @return [filtered_string]
    #
    def safe_characters(characters)

      return characters if characters.blank?
      safe_paragraph = ""
      characters.each_char do |letter|
        safe_letter = letter.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s
        safe_letter = letter.parameterize if safe_letter.blank?
        safe_paragraph += safe_letter.present? ? safe_letter : letter
      end
      safe_paragraph
    end

    # get percent match for first name
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # Sets @comparison_percent[:first_name]
    #
    def compare_first_name
      first_name = @document_details[:first_name]
      return if first_name.blank?

      params  = {
          paragraph:@safe_paragraph,
          match_string: first_name
      }

      first_name = safe_characters(first_name)
      first_name_percentage = Ocr::FieldComparison::NameComparison.new(params).perform
      @comparison_percent[:first_name] = first_name_percentage

    end

    # get percent match for last name
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # Sets @comparison_percent[:last_name]
    #
    def compare_last_name
      last_name = @document_details[:last_name]
      return if last_name.blank?

      params  = {
          paragraph:@safe_paragraph,
          match_string: last_name
      }

      last_name = safe_characters(last_name)
      last_name_percentage = Ocr::FieldComparison::NameComparison.new(params).perform
      @comparison_percent[:last_name] = last_name_percentage

    end

    # get percent match for birthdate
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # Sets @comparison_percent[:birthdate]
    #
    def compare_birthdate
      birthdate = @document_details[:birthdate]
      return if birthdate.blank?

      params  = {
          paragraph:@safe_paragraph,
          match_string: birthdate
      }

      birthdate = safe_characters(birthdate)
      birthdate_percentage = Ocr::FieldComparison::BirthdateComparison.new(params).perform
      @comparison_percent[:birthdate] = birthdate_percentage

    end

    # get percent match for document id
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # Sets @comparison_percent[:document_id]
    #
    def compare_document_id
      document_id = @document_details[:document_id]
      return if document_id.blank?

      params  = {
          paragraph:@safe_paragraph,
          match_string: document_id
      }

      document_id = safe_characters(document_id)
      document_id_percentage = Ocr::FieldComparison::DocumentIdNameComparison.new(params).perform
      @comparison_percent[:document_id] = document_id_percentage
    end

    # get percent match for rotation angle
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    # Sets @rotation_angle
    #
    def get_orientation
      return if @dimensions.blank?

      params  = {
          words_array:@dimensions
      }

      rotation_angle = Ocr::GetOrientation.new(params).get_orientation
      @rotation_angle = rotation_angle

    end

    # Api response data
    #
    # * Author: Aniket
    # * Date: 05/07/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      @result_hash[:comparison_percent] = @comparison_percent
      @result_hash[:rotation_angle] = @rotation_angle

      @result_hash
    end

  end

end
