# frozen_string_literal: true
module GlobalConstant

  class TokenSale

    class << self

      def st_token_sale_active_status
        GlobalConstant::Base.st_token_sale['active_status']
      end

      def pre_sale_register_start_date
        #'2017-11-01 00:00:00'
        Time.zone.parse(GlobalConstant::Base.st_token_sale['pre_sale_register_start_date'])
      end

      def pre_sale_two_register_start_date
        #'2017-11-11 00:00:00'
        Time.zone.parse(GlobalConstant::Base.st_token_sale['pre_sale_two_register_start_date'])
      end

      def public_sale_register_start_date
        #'2017-11-15 00:00:00'
        Time.zone.parse(GlobalConstant::Base.st_token_sale['public_sale_register_start_date'])
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
        if time >= public_sale_register_start_date
          open_sale_token_sale_phase
        elsif time >= pre_sale_two_register_start_date
          pre_phase_two_token_sale_phase
        else
          pre_sale_token_sale_phase
        end
      end

    end

  end

end
