namespace :onetimer do

  # Update backpopulate rows in user_kyc_comparison_details
  #
  # * Author: Aman
  # * Date: 10/08/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:backpopulate_rows_in_ocr_comparision_table
  #
  task :backpopulate_rows_in_ocr_comparision_table => :environment do

    max_user_extended_detail_id = get_max_user_extended_detail_id

    UserExtendedDetail.where('id <= ?', max_user_extended_detail_id).find_in_batches(batch_size: 100) do |ueds|
      user_ids = ueds.map(&:user_id).uniq
      users = User.where(id: user_ids).all.index_by(&:id)

      ueds.each do |ued|
        client_id = users[ued.user_id].client_id
        UserKycComparisonDetail.create!(user_extended_detail_id: ued.id, client_id: client_id,
                                        image_processing_status: GlobalConstant::ImageProcessing.unprocessed_image_process_status)
      end


    end

  end

  def get_max_user_extended_detail_id
    max_ued_id = UserExtendedDetail.maximum(:id)
    min_ued_id_in_ocr_comparision = UserKycComparisonDetail.minimum(:user_extended_detail_id).to_i
    return max_ued_id if min_ued_id_in_ocr_comparision == 0 || min_ued_id_in_ocr_comparision > max_ued_id
    return min_ued_id_in_ocr_comparision - 1
  end

end