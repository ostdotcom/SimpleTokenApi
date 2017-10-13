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

      def allowed_countries
        @allowed_countries ||= YAML.load_file(open(Rails.root.to_s + '/config/allowed_countries.yml'))[:countries]
      end

      def allowed_nationalities
        @allowed_nationalities ||= YAML.load_file(open(Rails.root.to_s + '/config/allowed_nationalities.yml'))[:nationalities]
      end

    end

  end

end
