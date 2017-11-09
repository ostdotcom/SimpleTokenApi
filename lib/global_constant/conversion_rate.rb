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
      def ether_to_usd_conversion_rate
        300.00
      end

      # Converts eth in wei to usd
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By:
      #
      # return [Deciaml] Converts eth in wei to usd
      #
      def wei_to_basic_unit(wei_count)
        ((wei_count * 1.00)/ether_to_wei_conversion_rate).to_f
      end

      # Converts eth in wei to usd
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By:
      #
      # return [Deciaml] Converts eth in wei to usd
      #
      def eth_in_wei_to_usd(eth_in_wei_count)
        (wei_to_basic_unit(eth_in_wei_count) * ether_to_usd_conversion_rate).round(2)
      end

    end

  end

end
