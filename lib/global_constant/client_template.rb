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

      def page_specific_template_types
        ::ClientTemplate.template_types.keys - [common_template_type]
      end

      def common
        {
            primary_button_style: '.client-primary-btn {border-color: #e4b030;background: #e4b030;color: #fff;}  .client-primary-btn.focus-cls, .client-primary-btn:focus {color: #fff;outline: none;text-decoration: none;}  .client-primary-btn.hover-cls, .client-primary-btn.active-cls, .client-primary-btn:hover, .client-primary-btn:active {color: #fff;text-decoration: none;background-color: #d4a326;border-color: #d4a326;}',
            secondary_button_style: '.client-secondary-btn {border-color: #7f9183;color: #7f9183;}  .client-secondary-btn:focus {color: #7f9183;outline: none;text-decoration: none;}  .client-secondary-btn:hover, .client-secondary-btn:active {color: #fff;text-decoration: none;background-color: #7f9183;border-color: #7f9183;}',
            header: {
                logo: {
                    href: '/',
                    alt: 'Simple Token Logo',
                    title: 'Simple Token',
                    src: 'https://d36lai1ppm9dxu.cloudfront.net/assets/logo/simple-token-dashboard-logo-1x.png',
                },
            },
            footer_html: '<footer style="width: 100%;position: absolute;font-size:14px;font-weight: 300;letter-spacing: 1.3px;text-align:center;padding:20px 10px;color:#9ea9a7;background:#e5efe8;">Copyright &copy; 2017 Simple Token. All Rights Reserved. <a href="https://simpletoken.org/privacy" title="Privacy Policy" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">Privacy Policy</a>, <a href="https://simpletoken.org/terms" title="Website Terms" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">Website Terms</a> and <a href="https://drive.google.com/file/d/0B1E_xJPbELBKeU9pUk5uSnNqWFU/view" title="OST Token Terms" target="_blank" style="color: #9ea9a7;text-decoration: none;border-bottom: 1px solid #9ea9a7;">OST Token Terms</a> </footer>',
            account_name: 'Simple Token',
            account_name_short: 'ST',
            blacklisted_countries: [
                'china',
                'afghanistan',
                'bosnia and herzegovina',
                'central african republic',
                'congo',
                'north korea',
                'eritrea',
                'ethiopia',
                'guinea-bissau',
                'iran',
                'iraq',
                'libya',
                'lebanon',
                'somalia',
                'south sudan',
                'sudan',
                'sri lanka',
                'syria',
                'tunisia',
                'vanuatu',
                'yemen',
                'cuba'
            ]
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
                update_kyc_checkbox_points_html: []
            }
        }
      end

      def dashboard
        {
            kyc_update_modal_text: 'By submitting new details, the previous ones will be lost.',
            telegram_href: 'https://www.t.me/simpletoken',
            early_purchase_ethereum_deposit_text: 'Individual Max Cap is 40 ETH.',
            ethereum_deposit_text_html: 'Set Gas Limit to 150,000.<br/><small>DO NOT use Coinbase, Kraken or any other exchange to purchase ST. Min Purchase 0.1 ETH</small>',
            ethereum_confirm_checkbox_points_html: [
                'I understand what Simple Tokens are. I also understand the risks.',
                'I am a sophisticated purchaser and I am not restricted under any law from purchasing Simple Tokens.',
                'I have read the English version of the <a href="https://drive.google.com/file/d/0B1E_xJPbELBKeU9pUk5uSnNqWFU/view" title="Terms and Condition" target="_blank" class="modal-ext-link">Terms and Conditions</a> cover to cover and I have understood and agree to them. I agree to monitor the <a href="https://sale.simpletoken.org/" class="modal-ext-link" target="_blank">website</a> for any updates.',
                'I have obtained all the professional advice I need.',
                'I agree that I will send payment from, and receive any Simple Tokens to, the Ethereum address I provided during registration.'

            ],
            timer_element_color: '#91c0ad',
            timer_element_gradient_style: 'color: #fff; background: linear-gradient( to bottom, #91c0ad 0%, #91c0ad 50%, #a7cdbd 51%, #a7cdbd 100%);',
            container_background_color: '#6c9ba9'

        }
      end

    end

  end

end
