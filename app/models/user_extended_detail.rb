class UserExtendedDetail < EstablishSimpleTokenUserDbConnection

  enum status: {
      GlobalConstant::User.active_status => 1,
      GlobalConstant::User.inactive_status => 2
  }

end
