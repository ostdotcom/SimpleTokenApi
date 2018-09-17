# frozen_string_literal: true
module GlobalConstant

  class Email

    class << self

      def default_from
        @default_from ||= case Rails.env
                            when 'staging'
                              'kyc.stagingnotifier@ost.com'
                            when 'development'
                              'kyc.stagingnotifier@ost.com'
                            else
                              'kyc.notifier@ost.com'
                          end
      end

      def default_to
        ['bala@ost.com', 'sunil@ost.com', 'pankaj@ost.com', 'aman@ost.com', 'aniket@ost.com', 'tejas@ost.com']
      end

      def default_pm_to
        ['francesco@ost.com']
      end

      def st_balance_report_email_to
        ['nishith@ost.com']
      end

      def contact_us_admin_email
        Rails.env.production? ? 'paul@simpletoken.org' : 'aman@ost.com'
      end

      def default_directors_to
        ['jason@ost.com', 'nishith@ost.com']
      end

      def default_eth_devs_to
        ['ben@ost.com', 'banks@ost.com']
      end

      def subject_prefix
        "STA #{Rails.env} : "
      end

    end

  end

end
