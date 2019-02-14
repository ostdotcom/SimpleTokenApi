module GlobalConstant
  class AdminSecret
    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def deleted_status
        'deleted'
      end

      ### Status End ###

    end
  end
end