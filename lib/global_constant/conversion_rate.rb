# frozen_string_literal: true
module GlobalConstant

  class ConversionRate

    class << self

      # Conversion rate for ether to wei
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By: Kedar
      #
      # return [Integer] conversion rate for ether to wei
      #
      def ether_to_wei_conversion_rate
        @ether_to_wei_conversion_rate ||= (10 ** 18)
      end

      # Conversion rate for st to usd
      #
      # * Author:Aman
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      # return [Integer] conversion rate for simple tokens to usd
      #
      def st_to_usd_conversion_rate
        0.083333
      end

      # Converts st in wei to usd
      #
      # * Author:Aman
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      # return [Deciaml] Converts st in wei to usd
      #
      def st_in_wei_to_usd(st_in_wei_count)
        (st_in_wei_count * st_to_usd_conversion_rate)/ether_to_wei_conversion_rate
      end

      # Converts eth in wei to usd
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By: Kedar
      #
      # return [Deciaml] Converts eth in wei to usd
      #
      def wei_to_basic_unit_in_string(wei_count)
        str = wei_count.to_s

        # pre-pend 0s
        if str.length < 19
          (19 - str.length).times do
            str = '0' + str
          end
        end

        # insert decimal
        str.insert(-19, '.')
        remove_trailing_zero_in_decimal(str)
      end

      # removes trailing zero in decimal
      #
      # * Author:Aman
      # * Date: 09/11/2017
      # * Reviewed By: Kedar
      #
      # return [String] removes trailing zero in decimal number
      #
      def remove_trailing_zero_in_decimal(str)
        return str if str.exclude?('.')

        last_index = str.length - 1
        digits_to_remove = 0

        while digits_to_remove <= last_index do
          ch = str[last_index - digits_to_remove]

          if ch == '.'
            digits_to_remove += 1
            break
          end

          break if ch != '0'

          digits_to_remove +=1
        end

        last_index = last_index - digits_to_remove
        str[0..last_index]
      end


    end

  end

end
