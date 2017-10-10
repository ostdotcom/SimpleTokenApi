# frozen_string_literal: true
module GlobalConstant

  class Cynopsis

    class << self

      def base_url
        GlobalConstant::Base.cynopsis['base_url']
      end

      def token
        GlobalConstant::Base.cynopsis['token']
      end

      def domain_name
        GlobalConstant::Base.cynopsis['domain_name']
      end

    end

  end

end
