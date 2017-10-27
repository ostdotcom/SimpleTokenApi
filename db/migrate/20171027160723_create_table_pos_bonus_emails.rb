class CreateTablePosBonusEmails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :pos_bonus_emails do |t|
        t.column :email, :string, limit: 255
        t.column :bonus_percentage, :float
      end
      add_index :pos_bonus_emails, [:email], unique: true, name: 'u_email'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :pos_bonus_emails
    end
  end

end
