class User < EstablishSimpleTokenUserDbConnection

  enum status: {
    GlobalConstant::User.active_status => 1,
    GlobalConstant::User.inactive_status => 2,
    GlobalConstant::User.deactived_status => 3
  }

  def self.cookie_value(user, user_secret)
    current_ts = Time.now.to_i
    token_e = Digest::MD5.hexdigest(
      "#{user.id}:#{user.password}:#{user_secret.id}:#{current_ts}:d"
    )

    "#{user.id}:#{current_ts}:d:#{token_e}"
  end

end
