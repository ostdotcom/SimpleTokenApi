class EntityGroupDraft < EstablishSimpleTokenCustomizationDbConnection

  enum entity_type: {
      GlobalConstant::EntityGroupDraft.theme_entity_type => 1,
      GlobalConstant::EntityGroupDraft.login_entity_type => 2,
      GlobalConstant::EntityGroupDraft.registration_entity_type => 3,
      GlobalConstant::EntityGroupDraft.reset_password_entity_type => 4,
      GlobalConstant::EntityGroupDraft.change_password_entity_type => 5,
      GlobalConstant::EntityGroupDraft.token_sale_blocked_region_entity_type => 6,
      GlobalConstant::EntityGroupDraft.kyc_form_entity_type => 7,
      GlobalConstant::EntityGroupDraft.dashboard_entity_type => 8,
      GlobalConstant::EntityGroupDraft.verification_entity_type => 9
  }

end