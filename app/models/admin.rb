class Admin < EstablishSimpleTokenAdminDbConnection

  enum status: {
           GlobalConstant::Admin.active_status => 1,
           GlobalConstant::Admin.inactive_status => 2,
           GlobalConstant::Admin.deactived_status => 3
       }


  # Add Admin
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [String] email
  # @param [String] password
  #
  def self.add_admin(email, password)

    email.to_s.downcase.strip!

    return 'Admin email/password is blank' if password.blank? || email.blank?
    return 'Invalid email address' if !Util::CommonValidator.is_valid_email?(email)
    return 'Admin email already present' if Admin.where(email: email).present?

    #udid = SecureRandom.hex(16)
    ga_secret = ROTP::Base32.random_base32

    #get ga_secret qr code
    rotp_client = TimeBasedOtp.new(ga_secret)
    r = rotp_client.provisioning_uri(email)
    return r unless r.success?
    otpauth = r.data[:otpauth]
    escaped_otpauth = CGI.escape(otpauth)
    url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{escaped_otpauth}"

    #get cmk key and text
    kms_login_client = Aws::Kms.new('login','admin')
    resp = kms_login_client.generate_data_key
    return resp unless resp.success?
    ciphertext_blob = resp.data[:ciphertext_blob]
    plaintext = resp.data[:plaintext]

    #encode password
    encrypted_password = Admin.get_encrypted_password(password, plaintext)

    #init encryptor obj with plaintext as secret key
    encryptor_obj = LocalCipher.new(plaintext)

    #get encrypted_ga_secret
    r = encryptor_obj.encrypt(ga_secret)
    return r unless r.success?
    encrypted_ga_secret = r.data[:ciphertext_blob]

    #create admin secrets
    admin_secrets_obj = AdminSecret.new(login_salt: ciphertext_blob, ga_secret: encrypted_ga_secret)
    admin_secrets_obj.save!(validate: false)

    #create admin
    admin_obj = Admin.new(email: email, password: encrypted_password,
      admin_secret_id: admin_secrets_obj.id, last_otp_at: Time.now.to_i, status: GlobalConstant::Admin.active_status)
    admin_obj.save!(validate: false)

    puts url
    return url
  end

  # Get encrypted password
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] password
  # @param [String] salt
  #
  # @return [String] MD5 Encrypted password
  #
  def self.get_encrypted_password(password, salt)
    Digest::MD5.hexdigest("#{password}::#{salt}")
  end

  # Get cookie value
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [Integer] admin_id - admin id
  # @param [String] password - password
  # @param [Timestamp] last_otp_at - last otp at
  # @param [String] auth_level - cookie auth level
  #
  # @return [String] cookie value
  #
  def self.get_cookie_value(admin_id, password, last_otp_at, browser_user_agent, auth_level)
    current_ts = Time.now.to_i
    token_e = get_cookie_token(admin_id, password, last_otp_at, auth_level, browser_user_agent, current_ts)
    "#{admin_id}:#{current_ts}:#{auth_level}:#{token_e}"
  end

  # Get cookie token
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [Integer] admin_id - admin id
  # @param [String] password - password
  # @param [Timestamp] last_otp_at - last otp at
  # @param [String] auth_level - cookie auth level
  # @param [String] browser_user_agent - browser user agent
  # @param [Integer] current_ts - current timestamp
  #
  # @return [String] cookie value
  #
  def self.get_cookie_token(admin_id, password, last_otp_at, auth_level, browser_user_agent, current_ts)
    # TODO: let's consider to use IP and user agent in cookie. And add last_otp_at
    Digest::MD5.hexdigest(
      "#{admin_id}:#{password}:#{last_otp_at}:#{current_ts}:#{browser_user_agent}:#{auth_level}"
    )
  end

end
