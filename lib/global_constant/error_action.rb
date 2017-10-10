# frozen_string_literal: true
module GlobalConstant

  class ErrorAction

    class << self

      def default
        'default'
      end

      def mandatory_params_missing
        'mandatory_params_missing'
      end

      def entity_not_found
        'entity_not_found'
      end

    end

  end

end
