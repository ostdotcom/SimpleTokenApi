# frozen_string_literal: true
module GlobalConstant

  class PublicOpsApi

    class << self

      def base_url
        GlobalConstant::Base.public_ops['base_url']
      end

      def secret_key
        GlobalConstant::Base.public_ops['secret_key']
      end

    end

  end

end

