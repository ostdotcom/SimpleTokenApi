class UserExtendedDetail < EstablishSimpleTokenUserDbConnection

  enum gender: {
      GlobalConstant::User.gender_male => 1,
      GlobalConstant::User.gender_female => 2
  }

end
