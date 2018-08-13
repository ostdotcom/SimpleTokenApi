class EntityGroup < EstablishSimpleTokenCustomizationDbConnection

  enum status: {
      GlobalConstant::EntityGroup.incomplete_status => 1,
      GlobalConstant::EntityGroup.active_status => 2,
      GlobalConstant::EntityGroup.deleted_status => 3
  }

end