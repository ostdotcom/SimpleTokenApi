# frozen_string_literal: true
module GlobalConstant

  class ErrorCode

    def self.ok
      200
    end

    def self.forbidden
      403
    end

    def self.not_found
      404
    end

    def self.permanent_redirect
      301
    end

    def self.allowed_http_codes
      [
        ok
      ]
    end

  end

end
