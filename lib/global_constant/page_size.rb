module GlobalConstant
  class PageSize
    class << self

      def default
        {
            default: 50,
            min: 1,
            max: 50
        }
      end

      def user_list
        default
      end

    end
  end
end
