class CreateUserKycActionLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :user_kyc_action_logs do |t|

        t.timestamps
      end
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_kyc_action_logs
    end
  end
end
