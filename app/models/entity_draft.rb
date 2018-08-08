class EntityDraft < EstablishSimpleTokenCustomizationDbConnection

  enum entity_type: {
      GlobalConstant::EntityDraft.theme_entity_type => 1,
      GlobalConstant::EntityDraft.login_entity_type => 2,
      GlobalConstant::EntityDraft.sign_up_entity_type => 3,
      GlobalConstant::EntityDraft.reset_password_entity_type => 4,
      GlobalConstant::EntityDraft.change_password_entity_type => 5,
      GlobalConstant::EntityDraft.token_sale_blocked_region_entity_type => 6,
      GlobalConstant::EntityDraft.kyc_form_entity_type => 7,
      GlobalConstant::EntityDraft.dashboard_entity_type => 8,
      GlobalConstant::EntityDraft.verification_entity_type => 9
  }

  enum status: {
      GlobalConstant::EntityDraft.active_status => 0,
      GlobalConstant::EntityDraft.draft_status => 1,
      GlobalConstant::EntityDraft.deleted_status => 2
  }

end
