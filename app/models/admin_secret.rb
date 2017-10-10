class AdminSecret < EstablishSimpleTokenAdminDbConnection


  def self.add_admin(email, password)
    udid = SecureRandom.hex(16)
    kms_login_client = Aws::Kms.new('login','admin')
    resp = kms_login_client.generate_data_key
    return resp unless resp.success?
    ciphertext_blob = resp.data[:ciphertext_blob]
    plaintext = resp.data[:plaintext]

    encrypted_password = Digest::MD5.hexdigest("#{password}::#{plaintext}")

    encryptor_obj = LocalCipher.new(plaintext)
    ga_secret = SecureRandom.random_bytes(64) + udid + Time.now.to_i.to_s
    r = encryptor_obj.encrypt(ga_secret)
    return r unless r.success?
    encrypted_ga_secret = r.data[:ciphertext_blob]


    rotp_client = Rotp::Totp.new(ga_secret)
    r = rotp_client.provisioning_uri(email)
    return r unless r.success?
    otpauth = r.data[:otpauth]
    url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{otpauth}"

    admin_obj = Admin.new(email: email, password: encrypted_password, status: 'active', udid: udid)
    admin_obj.save!(validate: false)

    admin_secrets_obj = AdminSecret.new(udid: udid, login_salt: ciphertext_blob, ga_secret: encrypted_ga_secret)
    admin_secrets_obj.save!(validate: false)
    puts url
  end

end
