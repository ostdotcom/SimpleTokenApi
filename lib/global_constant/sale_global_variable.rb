# frozen_string_literal: true
module GlobalConstant

  class SaleGlobalVariable

    class << self

      ########## variable kinds ###########

      def sale_ended_variable_kind
        'sale_ended_variable_kind'
      end

      def last_block_processed_variable_kind
        'last_block_processed_variable_kind'
      end

      def last_block_verified_for_tokens_sold_variable_kind
        'last_block_verified_for_tokens_sold_variable_kind'
      end

      def pre_sale_tokens_sold_variable_kind
        'pre_sale_tokens_sold_variable_kind'
      end

      def pre_sale_eth_received_variable_kind
        'pre_sale_eth_received_variable_kind'
      end

      ########## variable kinds ###########

    end

  end

end
