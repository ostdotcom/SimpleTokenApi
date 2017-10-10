class Admin < EstablishSimpleTokenAdminDbConnection

  enum status: {"active" => 1, "inactive" => 2, "deactivated" => 3}

end
