# frozen_string_literal: true
module GlobalConstant

  class TokenSale

    class << self

      def st_token_sale_active_status
        GlobalConstant::Base.st_token_sale['active_status']
      end

      def pre_sale_start
        Date.parse('2017-11-01')
      end

      def pre_phase_two_start
        Date.parse('2017-11-11')
      end

      def open_sale_start
        Date.parse('2017-11-15')
      end

      def pre_sale_token_sale_phase
        'pre_sale'
      end

      def pre_phase_two_token_sale_phase
        'pre_phase_two'
      end

      def open_sale_token_sale_phase
        'open_sale'
      end

      def token_sale_phase_for(time = Time.now)
        if time >= open_sale_start
          open_sale_token_sale_phase
        elsif time >= pre_phase_two_start
          pre_phase_two_token_sale_phase
        else
          pre_sale_token_sale_phase
        end
      end

    end

  end

end
