class DeletedUser < EstablishSimpleTokenUserDbConnection

  enum status: {
      GlobalConstant::DeletedUser.active_status => 1,
      GlobalConstant::DeletedUser.reactived_status => 2
  }
end
