class CreateUserUtmLog < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do

      create_table :user_utm_logs do |t|
        t.column :user_id, :integer, limit: 8, null: false
        t.column :origin_page, :string, limit: 255
        t.column :utm_type, :string, limit: 50
        t.column :utm_medium, :string, limit: 255
        t.column :utm_source, :string, limit: 255
        t.column :utm_term, :string, limit: 255
        t.column :utm_campaign, :string, limit: 255
        t.column :utm_content, :string, limit: 255
      end

      add_index :user_utm_logs, [:user_id], unique: true, name: 'u_user_id'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_utm_logs
    end
  end
end