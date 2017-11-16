namespace :onetimer do

  # rake RAILS_ENV=development onetimer:update_has_purchased_attribute_to_pepo_campaign

  task :update_has_purchased_attribute_to_pepo_campaign => :environment do

    purchased_user_ids = []

    PurchaseLog.all.each do |pl|

      ethereum_address = pl.ethereum_address

      purchased_user_ids << Md5UserExtendedDetail.get_user_id(ethereum_address)

    end

    purchased_user_ids.uniq!

    User.where(id: purchased_user_ids).order(:id).each do |user|
      Email::HookCreator::UpdateContact.new(
          email: user.email,
          custom_attributes: {
              GlobalConstant::PepoCampaigns.token_sale_has_purchased_attribute => GlobalConstant::PepoCampaigns.token_sale_has_purchased_value
          }
      ).perform
    end

  end

end
