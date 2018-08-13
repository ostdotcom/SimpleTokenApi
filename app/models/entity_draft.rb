class EntityDraft < EstablishSimpleTokenCustomizationDbConnection

  serialize :data, Hash

  enum status: {
      GlobalConstant::EntityDraft.draft_status => 1,
      GlobalConstant::EntityDraft.active_status => 2,
      GlobalConstant::EntityDraft.deleted_status => 3
  }

end
