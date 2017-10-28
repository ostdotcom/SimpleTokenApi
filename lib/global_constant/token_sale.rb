# frozen_string_literal: true
module GlobalConstant

  class TokenSale

    class << self

      def st_token_sale_active_status
        GlobalConstant::Base.st_token_sale['critical_details']['active_status']
      end

      def st_foundation_ethereum_address
        GlobalConstant::Base.st_token_sale['critical_details']['foundation_ethereum_address']
      end

      def early_access_register_end_date
        Time.zone.parse(GlobalConstant::Base.st_token_sale['user_register_dates']['early_access_register_end_date'])
      end

      def early_access_start_date
        Time.zone.parse(GlobalConstant::Base.st_token_sale['sale_dates']['early_access_start_date'])
      end

      def general_access_start_date
        Time.zone.parse(GlobalConstant::Base.st_token_sale['sale_dates']['general_access_start_date'])
      end

      def general_access_end_date
        Time.zone.parse(GlobalConstant::Base.st_token_sale['sale_dates']['general_access_end_date'])
      end

      def is_general_sale_interval?
        (Time.now >= GlobalConstant::TokenSale.general_access_start_date) && (Time.now < GlobalConstant::TokenSale.general_access_end_date)
      end

      def is_general_sale_ended?
        Time.now >= GlobalConstant::TokenSale.general_access_end_date
      end

      def early_access_token_sale_phase
        'early_access'
      end

      def general_access_token_sale_phase
        'general_access'
      end

      def token_sale_phase_for(time = Time.now)
        if time >= early_access_register_end_date
          general_access_token_sale_phase
        else
          early_access_token_sale_phase
        end
      end

    end

  end

end
