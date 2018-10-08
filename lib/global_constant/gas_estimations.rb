# frozen_string_literal: true
module GlobalConstant

  class GasEstimations

    class << self

      ###  Start ###

      def max_gas_price
        config[:max_gas_price]
      end

      def min_gas_price
        config[:min_gas_price]
      end

      def buffer_gas
        config[:buffer_gas]
      end

      def default_gas_price
        config[:default_gas_price]
      end

      ### End ###

      private

      def config
        GlobalConstant::Base.estimated_gas_constants
      end

    end

  end

end
