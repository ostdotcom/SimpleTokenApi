class TokenSaleDoubleOptInToken < EstablishSimpleTokenEmailDbConnection

  enum status: {
    GlobalConstant::TokenSaleDoubleOptInToken.active_status => 1,
    GlobalConstant::TokenSaleDoubleOptInToken.used_status => 2,
  }

end
