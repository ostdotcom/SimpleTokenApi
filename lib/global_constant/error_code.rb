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


    def self.http_code_map
      {
          permanent_redirect => 'PERMANENT_REDIRECT',
          temporary_redirect => 'TEMPORARY_REDIRECT',
          invalid_request_parameters => 'BAD_REQUEST',
          unauthorized_access => "UNAUTHORIZED",
          forbidden => "FORBIDDEN",
          not_found => "NOT_FOUND",
          unprocessable_entity => "UNPROCESSABLE_ENTITY",
          unhandled_exception => 'INTERNAL_SERVER_ERROR',
      }
    end

    def self.error_code_for_http_code(http_code)
      http_code_map[http_code].to_s
    end


  end

end
