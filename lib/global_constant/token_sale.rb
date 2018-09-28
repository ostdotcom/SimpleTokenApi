# frozen_string_literal: true
module GlobalConstant

  class TokenSale

    class << self

      def st_token_sale_client_id
        GlobalConstant::Base.st_token_sale['default_client_id']
      end

      def simple_token_contract_address
        GlobalConstant::Base.st_token_sale['critical_details']['simple_token_contract_address']
      end

      def early_access_token_sale_phase
        'early_access'
      end

      def general_access_token_sale_phase
        'general_access'
      end

    end

  end

end
