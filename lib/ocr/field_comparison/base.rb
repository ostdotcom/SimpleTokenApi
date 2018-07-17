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

      # Get filtered passport line
      # remove any extra characters before the Machine-readable_passport line
      #
      # * Author: Aniket
      # * Date: 11/07/2018
      # * Reviewed By:
      #
      # @return [String]
      #
      # refer for different formats - https://en.wikipedia.org/wiki/Machine-readable_passport
      #
      def sanitize_machine_readable_passport_line(line)
        return "" unless is_machine_readable_passport_line?(line)

        pos = line.index('p<')
        pos.nil? ? "" : line[pos..-1].gsub(/ /, '')
      end

      # check if its is a machine readable passport line
      #
      # * Author: Amam
      # * Date: 17/07/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      #
      def is_machine_readable_passport_line?(line)
        line.count('<') >= 3
      end

      def compare
        fail 'compare method is not implemented'
      end

    end
  end
end