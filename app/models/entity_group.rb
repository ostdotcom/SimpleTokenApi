class EntityGroup < EstablishSimpleTokenCustomizationDbConnection

  enum status: {
      GlobalConstant::EntityDraft.active_status => 1,
      GlobalConstant::EntityDraft.deleted_status => 2
  }

end