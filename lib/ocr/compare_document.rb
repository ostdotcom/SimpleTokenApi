module Ocr

  class CompareDocument

    # Initialize
    # @params [Array] words_array(mandatory)
    # @params [String] match_string(mandatory)
    #
    # Sets @words_array, @match_string
    #
    # @return [Ocr::CompareDocument.new()]
    #
    #* Author: Aniket/Tejas
    #* Date: 04/07/2018
    #* Reviewed By:
    #

    def initialize(words_array, document_details)

      @words_array = words_array
      @document_details = document_details

      @result_hash = {
          document_details: document_details
      }


    end

    def perform

      compare_first_name

      compare_last_name

      compare_birthdate

      compare_document_id

      success_response_data

    end

    private

    def compare_first_name
      first_name = @document_details[:first_name]
      first_name_percentage = Ocr::FieldComparison::NameComparison.new(words_array,first_name).perform
    end

    def compare_last_name
      last_name = @document_details[:last_name]
      last_name_percentage = Ocr::FieldComparison::NameComparison.new(words_array,last_name).perform
    end

    def compare_birthdate
      birthdate = @document_details[:last_name]
      birthdate_percentage = Ocr::FieldComparison::BirthdateComparison.new(words_array,birthdate).perform
    end

    def compare_document_id
      document_id = @document_details[:last_name]
      document_id_percentage = Ocr::FieldComparison::DocumentIdNameComparison.new(words_array,document_id).perform
    end

    def success_response_data

        @result_hash

    end

  end

end
