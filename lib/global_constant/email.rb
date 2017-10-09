# frozen_string_literal: true
module GlobalConstant

  class Email

    class << self

      def default_from
        'notifier@simpletoken.org'
      end

      def default_to
        ['bala@pepo.com', 'sunil@pepo.com', 'kedar@pepo.com', 'abhay@pepo.com']
      end

      def subject_prefix
        "STA #{Rails.env} : "
      end

    end

  end

end
