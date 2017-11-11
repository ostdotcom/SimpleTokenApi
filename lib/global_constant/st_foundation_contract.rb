# frozen_string_literal: true
module GlobalConstant

  class StFoundationContract

    class << self

      def token_sale_contract_address
        GlobalConstant::Base.st_foundation_contracts['token_sale']
      end

    end

  end

end
