class Admin < EstablishSimpleTokenAdminDbConnection

  enum status: {
      GlobalConstant::Admin.active_status => 1,
      GlobalConstant::Admin.invited_status => 2,
      GlobalConstant::Admin.deleted_status => 3
  }

  enum role: {
      GlobalConstant::Admin.normal_admin_role => 1,
      GlobalConstant::Admin.super_admin_role => 2
  }

  scope :not_deleted, -> {where(status: [GlobalConstant::Admin.active_status, GlobalConstant::Admin.invited_status])}

  after_commit :memcache_flush

  # Add Admin
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [String] email
  # @param [String] password
  #
  def self.add_admin(default_client_id, email, password, name, is_super_admin_role=false)

    email = email.to_s.downcase.strip
    name = name.to_s.strip

    return 'Admin email/password is blank' if password.blank? || email.blank? || name.blank? || password.length < 8
    return 'Invalid email address' if !Util::CommonValidator.is_valid_email?(email)
    return 'Admin email already present' if Admin.where(email: email).present?

    client = Client.get_from_memcache(default_client_id)
    return 'Invalid client id' unless client.present?

    ga_secret = ROTP::Base32.random_base32

    #get ga_secret qr code
    rotp_client = TimeBasedOtp.new(ga_secret)
    r = rotp_client.provisioning_uri(client.name)
    return r unless r.success?
    otpauth = r.data[:otpauth]
    escaped_otpauth = CGI.escape(otpauth)
    url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{escaped_otpauth}"

    #get cmk key and text
    kms_login_client = Aws::Kms.new('login', 'admin')
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

    admin_role = is_super_admin_role ? GlobalConstant::Admin.super_admin_role : GlobalConstant::Admin.normal_admin_role

    admin_obj = Admin.new(email: email, password: encrypted_password, name: name, default_client_id: default_client_id,
                          admin_secret_id: admin_secrets_obj.id, status: GlobalConstant::Admin.active_status, role: admin_role)
    admin_obj.save!(validate: false)

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
    string_to_sign = "#{admin_id}:#{password}:#{last_otp_at}:#{current_ts}:#{browser_user_agent}:#{auth_level}"
    key = "#{admin_id}:#{current_ts}:#{last_otp_at}:#{browser_user_agent}:#{password[-12..-1]}:#{GlobalConstant::SecretEncryptor.cookie_key}"
    sha256_params = {
        string: string_to_sign,
        salt: key
    }
    Sha256.new(sha256_params).perform
  end

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('admin.admin_details')
  end

  # Get/Set Memcache data for User
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  # @param [Integer] user_id - user id
  #
  # @return [AR] User object
  #
  def self.get_from_memcache(admin_id)
    memcache_key_object = Admin.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: admin_id}, memcache_key_object.expiry) do
      Admin.where(id: admin_id).first
    end
  end

  # Get email ids of all admins of a client
  #
  # * Author: Aman
  # * Date: 23/01/2018
  # * Reviewed By:
  #
  # @param [Integer] client id
  #
  # @return [Array <String>] emails of admin
  #
  def self.client_admin_emails(client_id)
    Admin.where(default_client_id: client_id, status: GlobalConstant::Admin.active_status).pluck(:email)
  end


  def self.client_super_admin_emails(client_id)
    Admin.where(default_client_id: client_id, status: GlobalConstant::Admin.active_status, role: GlobalConstant::Admin.super_admin_role ).pluck(:email)

  end


  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 09/01/2018
  # * Reviewed By:
  #
  def memcache_flush
    admin_details_memcache_key = Admin.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(admin_details_memcache_key)
  end

end
