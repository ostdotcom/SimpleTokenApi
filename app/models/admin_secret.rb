class AdminSecret < EstablishSimpleTokenAdminDbConnection

  belongs_to :admin, :primary_key => 'udid', :foreign_key => 'udid'




end
