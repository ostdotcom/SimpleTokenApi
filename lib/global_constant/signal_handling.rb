module GlobalConstant
  class SignalHandling
    class << self

      def sigint_received?
        @sigint_received == true
      end

      def sigint_received!
        @sigint_received = true
      end

    end
  end
end

