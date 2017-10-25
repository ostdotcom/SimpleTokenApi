# frozen_string_literal: true
module GlobalConstant

  class PrivateOpsApi

    class << self

      def base_url
        GlobalConstant::Base.private_ops['base_url']
      end

      def secret_key
        GlobalConstant::Base.private_ops['secret_key']
      end

    end

  end

end
