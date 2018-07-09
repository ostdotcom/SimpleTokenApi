module Ocr

  module FieldComparison

    class Base

      # Initialize
      #
      # * Author: Aniket
      # * Date: 28/06/2018
      # * Reviewed By:
      #
      # @params [String] Safe paragraph downcased- paragraph(mandatory)
      # @params [String] Safe string to match downcased- match_string(mandatory)
      #
      # @return [Ocr::FieldComparison::Base]
      #
      def initialize(params)
        @paragraph = params[:paragraph]
        @match_string = params[:match_string]
      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Integer]
      #
      def perform
        compare
      end

      private

      # * Author: Aniket
      # * Date: 06/06/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      # refer for different formats - https://en.wikipedia.org/wiki/Machine-readable_passport
      #
      def is_machine_readable_passport_line?(line)
        line.count('<') > 3
      end


      def compare
        fail 'compare method is not implemented'
      end

    end
  end
end