module GlobalConstant

  class EntityGroupDraft

    class << self

      ### Entity type Start ###

      def theme_entity_type
        'theme'
      end

      def registration_entity_type
        'registration'
      end

      def dashboard_entity_type
        'dashboard'
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

      def kyc_entity_type
        'kyc'
      end

      def verification_entity_type
        'verification'
      end

      def allowed_entity_types_from_fe
        [theme_entity_type, registration_entity_type, kyc_entity_type, dashboard_entity_type]
      end



      ### Entity type End ###

    end

  end

end
