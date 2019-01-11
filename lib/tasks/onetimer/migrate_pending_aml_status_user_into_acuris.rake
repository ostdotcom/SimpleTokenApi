namespace :onetimer do

  # Migrate Pending Aml Status User Into Acuris
  #
  # * Author: Tejas
  # * Date: 11/01/2019
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:migrate_pending_aml_status_user_into_acuris
  task :migrate_pending_aml_status_user_into_acuris => :environment do
    UserKycDetail.where(aml_status: GlobalConstant::UserKycDetail.aml_open_statuses).all.each do |ukd|
      next if ukd.kyc_denied? || (ukd.client_id == GlobalConstant::TokenSale.st_token_sale_client_id)
      AmlSearch.create!(uuid: ukd.get_aml_search_uuid,
                        user_kyc_detail_id: ukd.id,
                        user_extended_detail_id: ukd.user_extended_detail_id,
                        status: GlobalConstant::AmlSearch.unprocessed_status,
                        steps_done: 0,
                        retry_count: 0,
                        lock_id: nil)
      ukd.aml_status = GlobalConstant::UserKycDetail.unprocessed_aml_status
      ukd.aml_user_id = nil
      ukd.save! if ukd.changed?
    end
  end
end