class TimeBasedOtp

  DRIFT_TIME = 30 # expiry time difference for otp

  include ::Util::ResultHelper

  # Initialize
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @return [TimeBasedOtp]
  #
  def initialize(secret)
    @secret = secret
  end

  # Verify the OTP
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] otp - Current OTP
  # @param [TimeStamp] last_otp_at - last otp generation timestamp. All opts generated <= last_otp_at will invalidate
  #
  # @return [Result::Base]
  #
  def verify_with_drift_and_prior(otp, last_otp_at = nil)
    begin
      verified_at_timestamp = client.verify_with_drift_and_prior(otp, DRIFT_TIME, last_otp_at)

      if verified_at_timestamp.present?
        return success_with_data(verified_at_timestamp: verified_at_timestamp)
      else
        return error_with_data(
          'r_t_1',
          'Otp is incorrect ' + otp,
          'Otp is incorrect',
          GlobalConstant::ErrorAction.default,
          {otp: otp}
        )
      end

    rescue => e
      return exception_with_data(
        e,
        'r_t_2',
        'exception in verify_with_drift_and_prior: ' + e.message,
        'Something went wrong.',
        GlobalConstant::ErrorAction.default,
        {otp: otp}
      )
    end
  end

  # Get provisioning url
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] name - Display Name
  #
  # @return [Result::Base]
  #
  def provisioning_uri(name)
    begin
      otpauth = client.provisioning_uri(name)
      return success_with_data(otpauth: otpauth)
    rescue => e
      return exception_with_data(
        e,
        'r_t_3',
        'exception in provisioning_uri: ' + e.message,
        'Something went wrong.',
        GlobalConstant::ErrorAction.default,
        {name: name}
      )
    end
  end

  private

  # Setup client for ROTP
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @return [Object] ROTP
  #
  def client
    env_name = Rails.env.production? ? '' :  " - #{Rails.env}"
    @client ||= ROTP::TOTP.new(@secret, issuer: "OST KYC")
  end

end