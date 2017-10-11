# frozen_string_literal: true
module GlobalConstant

  class Regex

    class << self

      def email
        /^[A-Z0-9]+[A-Z0-9_%+-]*(\.[A-Z0-9_%+-]{1,})*@(?:[A-Z0-9](?:[A-Z0-9-]*[A-Z0-9])?\.)+[A-Z]{2,6}$/i
      end

    end

  end

end
