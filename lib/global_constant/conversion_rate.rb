# frozen_string_literal: true
module GlobalConstant

  class ConversionRate

    class << self

      # Conversion rate for ether to wei
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By:
      #
      # return [Integer] conversion rate for ether to wei
      #
      def ether_to_wei_conversion_rate
        @ether_to_wei_conversion_rate ||= (10 ** 18)
      end

      # Conversion rate for usd to ether
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By:
      #
      # return [Integer] conversion rate for ether to wei
      #
      def usd_to_ether_conversion_rate
        300.00
      end

    end

  end

end
