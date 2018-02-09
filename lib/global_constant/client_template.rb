# frozen_string_literal: true
module GlobalConstant

  class ClientTemplate

    class << self

      ### Template type Start ###

      def common_template_type
        'common'
      end

      def login_template_type
        'login'
      end

      def sign_up_template_type
        'sign_up'
      end

      def reset_password_template_type
        'reset_password'
      end

      def change_password_template_type
        'change_password'
      end

      def token_sale_blocked_region_template_type
        'token_sale_blocked_region'
      end

      def kyc_template_type
        'kyc'
      end

      def dashboard_template_type
        'dashboard'
      end

      ### Template type End ###

      def allowed_template_types
        ClientTemplate.template_types
      end

      # def common
      #   {
      #       blacklisted_country_for_ip: [],
      #       primary_button_color: '',
      #       secondary_button_color: '',
      #       header: {
      #           logo: {
      #               href: '',
      #               alt: '',
      #               title: '',
      #               src: '',
      #           },
      #       },
      #       footer_html: '',
      #       account_name: ''
      #   }
      # end
      #
      # def login
      #   {
      #   }
      # end
      #
      # def sign_up
      #   {
      #       checkbox_html: ''
      #   }
      # end
      #
      # def reset_password
      #   {
      #   }
      # end
      #
      # def change_password
      #   {
      #   }
      # end
      #
      # def token_sale_blocked_region
      #   {
      #       primary_button_href: '',
      #   }
      # end
      #
      # def kyc
      #   {
      #       ethereum_address_info_html: '',
      #       document_info_html: '',
      #
      #       verify_modal: {
      #           add_kyc_checkbox_texts: ['', ''],
      #           update_kyc_checkbox_texts: ['', '']
      #       }
      #   }
      # end
      #
      # def dashboard
      #   {}
      # end

    end

  end

end
