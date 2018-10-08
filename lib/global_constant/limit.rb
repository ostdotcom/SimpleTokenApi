module GlobalConstant
  class Limit
    class << self

      def default
        {
            default: 10,
            min: 1,
            max: 100
        }
      end

      def user_list
        default
      end

      def user_kyc
        default
      end

    end
  end
end
