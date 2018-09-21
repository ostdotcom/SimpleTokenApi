module GlobalConstant
  class PageSize
    class << self

      def default
        {
            default: 50,
            min: 10,
            max: 50
        }
      end

      def user_list
        {
            default: 3,
            min: 2,
            max: 50
        }
      end

    end
  end
end
