module Rotp

  class Totp

    DRIFT_TIME = 30 # expiry time difference for otp

    include ::Util::ResultHelper

    def initialize(secret)
      @secret = secret
    end

    def verify_with_drift_and_prior(otp, last_otp_at = nil)
      begin
        verified_at_timestamp = client.verify_with_drift_and_prior(otp, DRIFT_TIME, last_otp_at)

        if verified_at_timestamp.present?
          return success_with_data(
              verified_at_timestamp: verified_at_timestamp
          )
        else
          return error_with_action_and_data(
              'r_t_1',
              'invalid otp ' + otp,
              'Invalid Otp',
              GlobalConstant::ApiErrorAction.default,
              {otp: otp}
          )
        end

      rescue => e
        return exception_with_action_and_data(
            e,
            'r_t_2',
            'exception in verify_with_drift_and_prior: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ApiErrorAction.default,
            {
                otp: otp
            }
        )
      end
    end

    def provisioning_uri(name)
      begin
      otpauth = client.provisioning_uri(name)
      return success_with_data(
          otpauth: otpauth
      )
      rescue => e
        return exception_with_action_and_data(
            e,
            'r_t_3',
            'exception in provisioning_uri: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ApiErrorAction.default,
            {
                name: name
            }
        )
      end
    end

    private

    def client
      @client ||= ROTP::TOTP.new(@secret, issuer: "Simple Token Api")
    end

  end

end