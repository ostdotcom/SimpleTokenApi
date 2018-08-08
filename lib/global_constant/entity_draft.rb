module GlobalConstant

  class EntityDraft

    class << self

      ### Entity type Start ###

      def theme_entity_type
        'common'
      end

      def login_entity_type
        'login'
      end

      def sign_up_entity_type
        'sign_up'
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
        'kyc'
      end

      def verification_entity_type
        'verification'
      end

      def dashboard_entity_type
        'dashboard'
      end

      ### Entity type End ###

      ### Status start ###

      def active_status
        'active'
      end

      def deleted_status
        'deleted'
      end

      def draft_status
        'draft'
      end

    end

  end

end
