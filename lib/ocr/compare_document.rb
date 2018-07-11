module Ocr

  class CompareDocument

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Aniket/Tejas
    # * Date: 04/07/2018
    # * Reviewed By: Aman
    #
    # @params [String] paragraph (mandatory) - paragraph
    # @params [Hash] document_details (mandatory) - details of user
    # @params [Array] dimensions (optional) - dimensions of words
    #
    # Sets @paragraph, @dimensions, @document_details, @comparison_percent, @result_hash
    #
    # @return [Ocr::CompareDocument]
    #
    def initialize(params)
      @paragraph = params[:paragraph].to_s
      @document_details = params[:document_details]

      @dimensions = params[:dimensions]

      @result_hash = {}

      @comparison_percent = {}
    end

    def perform
      @safe_paragraph = safe_characters(@paragraph)

      compare_first_name

      compare_last_name

      compare_birthdate

      compare_document_id

      compare_nationality

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
    def safe_characters(paragraph)
      Util::CommonValidateAndSanitize.safe_paragraph(paragraph)
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

      first_name = safe_characters(first_name)

      params  = {
          paragraph: @safe_paragraph,
          match_string: first_name
      }

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

      last_name = safe_characters(last_name)

      params  = {
          paragraph:@safe_paragraph,
          match_string: last_name
      }

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
      document_id = @document_details[:document_id_number]
      return if document_id.blank?

      document_id = safe_characters(document_id)

      params  = {
          paragraph:@safe_paragraph,
          match_string: document_id
      }

      document_id_percentage = Ocr::FieldComparison::DocumentIdNumberComparison.new(params).perform
      @comparison_percent[:document_id_number] = document_id_percentage
    end

    def compare_nationality

      nationality = @document_details[:nationality]
      return if nationality.blank?

      nationality = safe_characters(nationality)

      params  = {
          paragraph:@safe_paragraph,
          match_string: nationality
      }

      nationality_percentage = Ocr::FieldComparison::NationalityComparison.new(params).perform
      @comparison_percent[:nationality] = nationality_percentage
    end

    # get percent match for rotation angle
    #
    #* Author: Aniket
    #* Date: 05/07/2018
    #* Reviewed By:
    #
    #
    def get_orientation
      return if @dimensions.blank?

      params  = {
          words_array:@dimensions
      }

      rotation_angle = Ocr::GetOrientation.new(params).get_orientation
      @result_hash[:rotation_angle] = rotation_angle
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
      @result_hash
    end

  end

end
