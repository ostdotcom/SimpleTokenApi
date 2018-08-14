module GlobalConstant

  class EntityGroup

    class << self

      def allowed_entity_types_from_fe
        [dashboard_entity_type,kyc_form_entity_type,theme_entity_type,registration_entity_type]
      end

      ### Entity type Start ###

      def theme_entity_type
        'theme'
      end

      def login_entity_type
        'login'
      end

      def reset_password_entity_type
        'reset_password'
      end

      def change_password_entity_type
        'change_password'
      end

      def token_sale_blocked_region_entity_type
        'token_sale_blocked_region'
      end

      def kyc_form_entity_type
        'kyc_form'
      end

      def verification_entity_type
        'verification'
      end

      def dashboard_entity_type
        'dashboard'
      end

      def registration_entity_type
        'registration'
      end

      ### Entity type End ###

      ### Status start ###

      def active_status
        'active'
      end

      def deleted_status
        'deleted'
      end

      def incomplete_status
        'incomplete'
      end

      ### Status End ###

    end

  end

end
