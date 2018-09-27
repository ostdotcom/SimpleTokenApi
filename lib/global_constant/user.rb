# frozen_string_literal: true
module GlobalConstant

  class User

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def deleted_status
        'deleted'
      end

      ### Status End ###

      ### Property start ###

      def token_sale_kyc_submitted_property
        'token_sale_kyc_submitted'
      end

      def token_sale_bt_done_property
        'token_sale_bt_done'
      end

      def token_sale_double_optin_mail_sent_property
        'token_sale_kyc_double_optin_mail_sent'
      end

      def token_sale_double_optin_done_property
        'token_sale_kyc_optin_done'
      end

      ### Property stop ###

      ### Token sale state related pages ####

      def get_token_sale_state_page_names(key)
        _page = token_sale_state_page_names[key.to_sym]
        fail "Token sale state (#{key}) related page not defined." if _page.blank?
        return _page
      end

      def token_sale_state_page_names
        @token_sale_state_page_names ||= {
            profile_page: 'profile_page',
            verification_page: 'verification_page',
            kyc_page: 'kyc_page'
        }
      end

      ### Token sale state related pages ####


      def sorting
        {
            "sort_by" => {
                'desc' => {id: :desc},
                'asc' => {id: :asc}
            }
        }
      end


      def is_kyc_submitted_filter
        'is_kyc_submitted'
      end
      def is_doptin_done_filter
        'is_doptin_done'
      end
      def is_doptin_mail_sent_filter
        'is_doptin_mail_sent'
      end
      def email_filter
        'email'
      end

      def allowed_filter
        [
          is_kyc_submitted_filter,
          is_doptin_done_filter,
          is_doptin_mail_sent_filter,
          email_filter
        ]
      end

      def filters
        {
          "#{is_kyc_submitted_filter}" => {
              "true" => ["(properties & ?) = ?",
                        ::User.properties_config[token_sale_kyc_submitted_property],
                        ::User.properties_config[token_sale_kyc_submitted_property]
              ],
              "false" => ["(properties & ?) = 0",
                        ::User.properties_config[token_sale_kyc_submitted_property]
              ]
          },
          "#{is_doptin_done_filter}" => {
              "true" => ["(properties & ?) = ?",
                         ::User.properties_config[token_sale_double_optin_done_property],
                         ::User.properties_config[token_sale_double_optin_done_property]
              ],
              "false" => ["(properties & ?) = 0",
                          ::User.properties_config[token_sale_double_optin_done_property]
              ]
          },
          "#{is_doptin_mail_sent_filter}" => {
              "true" => ["(properties & ?) = ?",
                         ::User.properties_config[token_sale_double_optin_mail_sent_property],
                         ::User.properties_config[token_sale_double_optin_mail_sent_property]
              ],
              "false" => ["(properties & ?) = 0",
                         ::User.properties_config[token_sale_double_optin_mail_sent_property]
              ]
          }
        }
      end



    end

  end

end
