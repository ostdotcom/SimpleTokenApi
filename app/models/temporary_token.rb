class TemporaryToken < EstablishSimpleTokenEmailDbConnection

  enum status: {
      GlobalConstant::TemporaryToken.active_status => 1,
      GlobalConstant::TemporaryToken.used_status => 2,
      GlobalConstant::TemporaryToken.inactive_status => 3,
  }

  enum kind: {
      GlobalConstant::TemporaryToken.double_opt_in_kind => 1,
      GlobalConstant::TemporaryToken.reset_password_kind => 2,
      GlobalConstant::TemporaryToken.admin_reset_password_kind => 3,
      GlobalConstant::TemporaryToken.admin_invite_kind => 4
  }

  def is_expired?
    #TODO:: Confirm if admin reset password expiry would be different.

    expiry_interval = case self.kind
                        when GlobalConstant::TemporaryToken.double_opt_in_kind
                          GlobalConstant::TemporaryToken.double_opt_in_expiry_interval
                        when GlobalConstant::TemporaryToken.admin_invite_kind
                          GlobalConstant::TemporaryToken.admin_invite_expiry_interval
                        else
                          GlobalConstant::TemporaryToken.reset_token_expiry_interval
                      end

    return (self.created_at.to_i + expiry_interval.to_i) < Time.now.to_i
  end

end
