class RemoveOpenCaseColumnFromEditKyc < DbMigrationConnection
  def self.up

    EditKycRequests.all.each do |ekr|
      Rails.logger.info "Edit Kyc request processing : #{ekr.id}"
      if ekr.open_case_only == 1
        ekr.update_action = GlobalConstant::EditKycRequest.open_case_update_action
        ekr.save
      elsif ekr.ethereum_address.present?
        ekr.update_action = GlobalConstant::EditKycRequest.update_ethereum_action
        ekr.save
      end
    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :edit_kyc_requests, :open_case_only
    end
  end
end
