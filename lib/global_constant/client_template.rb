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


      def common
        {
            blacklisted_country_for_ip: [],
            primary_button_color: '',
            secondary_button_color: '',
            header: {
                logo: {
                    href: '',
                    alt: '',
                    title: '',
                    src: '',
                },
                logout_cta: ''
            },
            footer_html: ''
        }
      end

      def login
        {
            email_address_label: '',
            password_label: '',
            forgot_password_label: '',

            primary_button_color: '',
            primary_button_cta: '',

            secondary_button_label: '',
            secondary_button_color: '',
            secondary_button_cta: ''
        }
      end

      def sign_up
        {
            email_address_label: '',
            password_label: '',
            password_info_text: '',
            checkbox_html: '',

            primary_button_color: '',
            primary_button_cta: '',

            secondary_button_label: '',
            secondary_button_color: '',
            secondarysecondary_button_cta: ''
        }
      end

      def reset_password
        {
            header: '',
            subheader: '',
            email_address_label: '',

            primary_button_color: '',
            primary_button_cta: '',

            secondary_button_color: '',
            secondary_button_cta: '',

            success: {
                header: '',
                text1: '',
                text2: '',
                secondary_button_label: '',
                secondary_button_color: '',
                secondarysecondary_button_cta: ''
            }

        }
      end

      def change_password
        {
            header: '',
            password_label: '',
            confirm_password_label: '',

            primary_button_color: '',
            primary_button_cta: '',

            success: {
                header: '',
                text1: '',
                primary_button_color: '',
                primary_button_cta: '',
            }

        }
      end

      def token_sale_blocked_region
        {
            header: '',
            subheader: '',
            primary_button_color: '',
            primary_button_cta: '',
            primary_button_href: '',
        }
      end

      def kyc
        {
            header: '',
            subheader: '',
            dob_info: '',
            ethereum_address: {
                text: '',
                learn_more: {
                    text: '',
                    cta: '',
                    href: ''
                }
            },

            passport_number_text: '',
            primary_button_cta: '',
            primary_button_href: '',

            verify_modal: {
                add_kyc: {
                    checkbox_texts: ['', '']
                },
                update_kyc: {
                    checkbox_texts: []
                },

                primary_button_color: '',
                primary_button_cta: ''
            }

        }
      end

      def dashboard
        {}
      end

    end

  end

end
