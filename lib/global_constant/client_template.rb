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

      def common
        {
            primary_button_color: '',
            secondary_button_color: '',
            header: {
                logo: {
                    href: '/',
                    alt: 'Simple Token Logo',
                    title: 'Simple Token',
                    src: 'https://d36lai1ppm9dxu.cloudfront.net/assets/logo/simple-token-dashboard-logo-1x.png',
                },
            },
            footer_html: '<footer class="navbar-fixed-bottom" style="font-size:14px;font-weight: 300;letter-spacing: 1.3px;text-align:center;padding:20px 10px;color:#9ea9a7;background:#e5efe8;">Copyright &copy; 2017 Simple Token. All Rights Reserved. <a href="https://simpletoken.org/privacy" title="Privacy Policy" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">Privacy Policy</a>, <a href="https://simpletoken.org/terms" title="Website Terms" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">Website Terms</a> and <a href="https://drive.google.com/file/d/0B1E_xJPbELBKeU9pUk5uSnNqWFU/view" title="OST Token Terms" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">OST Token Terms</a> </footer>',
            account_name: 'Simple Token'
        }
      end

      def login
        {
        }
      end

      def sign_up
        {
            checkbox_html: 'By checking this box, you agree to our <a href="https://simpletoken.org/terms" title="Terms of Service" target="_blank">Terms of Service</a> and acknowledge and consent to our <a href="https://simpletoken.org/privacy" title="Privacy Policy" target="_blank">Privacy Policy</a>.'
        }
      end

      def reset_password
        {
        }
      end

      def change_password
        {
        }
      end

      def token_sale_blocked_region
        {
            primary_button_href: 'https://simpletoken.org/terms',
        }
      end

      def kyc
        {
            ethereum_address_info_html: 'Make sure to use your Ethereum Wallet address and not addresses from exchanges like Coinbase,Poloniex, Kraken.<br/><a href="https://docs.google.com/document/d/1WVPQyUZgul81MoF2DkmsAeA6vPpKJ8vtjS53GWeSov4/edit" title="Learn more" target="_blank">Learn more</a>',
            document_info_html: 'A valid ID Document is required for the verification <br/>process. In addition to Government Issued Passports, <br/>National IDs and Drivers License are also accepted.',

            verify_modal: {
                add_kyc_checkbox_points_html: [
                    'All the information I have entered is true and complete.',
                    'I am not restricted under any law from providing this information or purchasing Simple Tokens.',
                    'I act on my own behalf, unless I have notified you in writing.',
                    'I have read, understood and agree to <a href="<%= GlobalConstant::Base.simple_token_web["root_url"] %>/privacy" target="_blank" class="modal-ext-link">OpenST Limited"s Privacy Policy</a>. I acknowledge this may change. I also understand that any purchase of Simple Tokens will be subject to additional terms and conditions.',
                    'I agree that I will send payment from, and receive any Simple Tokens to, the digital wallet address I have entered on this website.'
                ],
                update_kyc_checkbox_points_html: ['', '']
            }
        }
      end

      def dashboard
        {}
      end

    end

  end

end
