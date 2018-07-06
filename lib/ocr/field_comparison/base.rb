module Ocr

  module FieldComparison

  class Base

    # Initialize
    # @params [Array] words_array(mandatory)
    # @params [String] match_string(mandatory)
    #
    # Sets @words_array, @match_string
    #
    # @return [Ocr::FieldComparison::Base.new()]
    #
    #* Author: Aniket
    #* Date: 28/06/2018
    #* Reviewed By:
    #
    def initialize(params)

      @paragraph = params[:paragraph]
      @match_string = params[:match_string]

    end

    def perform

      compare

    end


    private

    def compare
        fail 'compare method is not implemented'
    end

  end
  end
end