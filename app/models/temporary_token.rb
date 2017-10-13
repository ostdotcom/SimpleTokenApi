class TemporaryToken < EstablishSimpleTokenEmailDbConnection

  enum status: {
           GlobalConstant::TemporaryToken.active_status => 1,
           GlobalConstant::TemporaryToken.used_status => 2,
           GlobalConstant::TemporaryToken.inactive_status => 3,
       }

  enum kind: {
           GlobalConstant::TemporaryToken.double_opt_in_kind => 1,
           GlobalConstant::TemporaryToken.reset_password_kind => 2,
       }

  def is_expired?
    expiry_interval = (self.kind == GlobalConstant::TemporaryToken.double_opt_in_kind) ? GlobalConstant::TemporaryToken.double_opt_in_expiry_interval : GlobalConstant::TemporaryToken.reset_token_expiry_interval
    return (self.created_at.to_i + expiry_interval.to_i) < Time.now.to_i
  end

end
