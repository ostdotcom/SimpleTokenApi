namespace :onetimer do

  # Update has purchased attribute to PC
  #
  # * Author: Aman, Abhay
  # * Date: 17/11/2017
  # * Reviewed By: Sunil
  #
  # rake RAILS_ENV=development onetimer:update_has_purchased_attribute_to_pepo_campaign
  #
  task :update_has_purchased_attribute_to_pepo_campaign => :environment do

    purchased_user_ids = []
    PurchaseLog.all.each do |pl|
      ethereum_address = pl.ethereum_address
      purchased_user_ids << Md5UserExtendedDetail.get_user_id(ethereum_address)
    end

    purchased_user_ids.uniq!

    User.where(id: purchased_user_ids).order(:id).each do |user|

      custom_attributes_to_update = {
        GlobalConstant::PepoCampaigns.token_sale_has_purchased_attribute => GlobalConstant::PepoCampaigns.token_sale_has_purchased_value
      }

      r = Email::Services::PepoCampaigns.new.update_contact(
        GlobalConstant::PepoCampaigns.master_list_id,
        user.email,
        custom_attributes_to_update
      )

      if r['error'].present?
        p "Error Updating Attribute: #{GlobalConstant::PepoCampaigns.token_sale_has_purchased_attribute} in sync for user: #{user.id}"
        p "Trying through hook processing in async"

        r = Email::HookCreator::UpdateContact.new(
          email: user.email,
          custom_attributes: custom_attributes_to_update
        ).perform

        if !r.success?
          p "Error Updating Attribute: #{GlobalConstant::PepoCampaigns.token_sale_has_purchased_attribute} for user: #{user.id}"
        end

      end

    end

  end

end
