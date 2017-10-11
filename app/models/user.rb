class User < EstablishSimpleTokenUserDbConnection

  enum status: {
    GlobalConstant::User.active_status => 1,
    GlobalConstant::User.inactive_status => 2,
    GlobalConstant::User.deactived_status => 3
  }

  def self.cookie_value(user, user_secret)
    current_ts = Time.now.to_i

    token_e = cookie_token(user.id, user.password, user_secret.id, current_ts)

    "#{user.id}:#{current_ts}:d:#{token_e}"
  end

  def self.cookie_token(user_id, password, user_secret_id, current_ts)
    Digest::MD5.hexdigest(
      "#{user_id}:#{password}:#{user_secret_id}:#{current_ts}:d"
    )
  end

end
