class RemoveColumnKycProblemEmailSentFromUserKycDetails < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :kyc_problem_email_sent
    end
  end
end
