class ClientTemplate < EstablishSimpleTokenClientDbConnection

  serialize :data, Hash

  enum template_type: {
           GlobalConstant::ClientTemplate.common_template_type => 1,
           GlobalConstant::ClientTemplate.login_template_type => 2,
           GlobalConstant::ClientTemplate.sign_up_template_type => 3,
           GlobalConstant::ClientTemplate.reset_password_template_type => 4,
           GlobalConstant::ClientTemplate.change_password_template_type => 5,
           GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type => 6,
           GlobalConstant::ClientTemplate.kyc_template_type => 7,
           GlobalConstant::ClientTemplate.dashboard_template_type => 8
       }

end