# frozen_string_literal: true
module GlobalConstant

  class ErrorCode

    def self.ok
      200
    end

    def self.unauthorized_access
      401
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

    def self.temporary_redirect
      302
    end

    def self.unprocessable_entity
      422
    end

    def self.invalid_request_parameters
      400
    end

    def self.unhandled_exception
      500
    end

    def self.allowed_http_codes
      [
        ok,
        unauthorized_access,
        not_found,
        forbidden,
        unprocessable_entity,
        invalid_request_parameters
      ]
    end

    def self.http_codes_for_web
      [
        ok,
        unauthorized_access,
        not_found,
        temporary_redirect
      ]
    end



  end

end
