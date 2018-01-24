# frozen_string_literal: true
module GlobalConstant

  class Email

    class << self

      def default_from
        Rails.env.production? ? 'notifier@simpletoken.org' : 'notifier@stagingsimpletoken.org'
      end

      def default_to
        ['bala@pepo.com', 'sunil@pepo.com', 'kedar@pepo.com', 'abhay@pepo.com', 'aman@pepo.com', 'alpesh@pepo.com', 'akshay@pepo.com', 'thahir@pepo.com']
      end

      def default_pm_to
        ['francesco@pepo.com']
      end

      def st_balance_report_email_to
        ['nishith@simpletoken.org']
      end

      def contact_us_admin_email
        Rails.env.production? ? 'support@simpletoken.org' : 'aman@ost.com'
      end

      def default_directors_to
        ['jason@simpletoken.org', 'nishith@simpletoken.org']
      end

      def default_eth_devs_to
        ['ben@simpletoken.org', 'banks@simpletoken.org']
      end

      def subject_prefix
        "STA #{Rails.env} : "
      end

    end

  end

end
