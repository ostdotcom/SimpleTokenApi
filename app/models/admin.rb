class Admin < EstablishSimpleTokenAdminDbConnection

  has_one :admin_secret, :primary_key => 'udid', :foreign_key => 'udid'

  enum status: {
           GlobalConstant::Admin.active_status => 1,
           GlobalConstant::Admin.inactive_status => 2,
           GlobalConstant::Admin.deactived_status => 3
       }


  def self.add_admin(email, password)
    udid = SecureRandom.hex(16)
    ga_secret = ROTP::Base32.random_base32

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

    #get ga_secret qr code
    rotp_client = Rotp::Totp.new(ga_secret)
    r = rotp_client.provisioning_uri(email)
    return r unless r.success?
    otpauth = r.data[:otpauth]
    escaped_otpauth = CGI.escape(otpauth)
    url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{escaped_otpauth}"

    #create admin and admin secret objects
    admin_obj = Admin.new(email: email, password: encrypted_password, status: 'active', udid: udid)
    admin_obj.save!(validate: false)

    admin_secrets_obj = AdminSecret.new(udid: udid, login_salt: ciphertext_blob, ga_secret: encrypted_ga_secret)
    admin_secrets_obj.save!(validate: false)
    puts url
  end


  def self.get_encrypted_password(password, salt)
    Digest::MD5.hexdigest("#{password}::#{salt}")
  end

end
