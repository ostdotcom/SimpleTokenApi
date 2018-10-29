module GlobalConstant

  class ClientPlan

    class << self

      ### Status start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### Add On start ###

      def whitelist_add_ons
        'whitelist'
      end

      def custom_front_end_add_ons
        'custom_front_end'
      end

      ### Add On start ###


      ### Notification Status start ###

      def first_threshold_notification_type
        'first_threshold'
      end

      def second_threshold_notification_type
        'second_threshold'
      end

      def max_threshold_notification_type
        'max_threshold'
      end

      ### Notification Status End ###
      #

      def first_threshold_percent
        60
      end

      def second_threshold_percent
        80
      end

      def max_threshold_percent
        95
      end

    end

  end
end
