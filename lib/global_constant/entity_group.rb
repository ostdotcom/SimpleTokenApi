module GlobalConstant

  class EntityGroup

    class << self

      def allowed_entity_types_from_fe
        [dashboard_entity_type,kyc_form_entity_type,theme_entity_type,registration_entity_type]
      end

      ### Status start ###

      def incomplete_status
        'incomplete'
      end

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