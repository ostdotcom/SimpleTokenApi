class AddIndexInEmailServiceApiCallHooks < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      add_index :email_service_api_call_hooks, [:email, :event_type], name: 'EMAIL_EVENT_TYPE_INDEX'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      remove_index :email_service_api_call_hooks, 'EMAIL_EVENT_TYPE_INDEX'
    end
  end

end
