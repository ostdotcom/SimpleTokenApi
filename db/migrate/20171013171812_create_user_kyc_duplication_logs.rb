class CreateUserKycDuplicationLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :user_kyc_duplication_logs do |t|

      t.timestamps
    end
  end
end
