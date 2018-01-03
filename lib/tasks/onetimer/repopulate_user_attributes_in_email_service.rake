namespace :onetimer do

  # rake RAILS_ENV=development onetimer:repopulate_user_attributes_in_email_service

  task :repopulate_user_attributes_in_email_service => :environment do

    # User.where(status: GlobalConstant::User.active_status).find_in_batches do |batched_users|
    #
    #   batched_users.each do |user|
    #
    #     custom_attributes = {
    #       GlobalConstant::PepoCampaigns.token_sale_registered_attribute => GlobalConstant::PepoCampaigns.token_sale_registered_value
    #     }
    #
    #     if user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")
    #       custom_attributes[GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_attribute] = GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_value
    #     end
    #
    #     add_update_contact_params = [
    #       GlobalConstant::PepoCampaigns.master_list_id,
    #       user.email,
    #       custom_attributes,
    #       {
    #         GlobalConstant::PepoCampaigns.double_opt_in_status_user_setting => GlobalConstant::PepoCampaigns.verified_value
    #       }
    #     ]
    #
    #     puts "#{user.email} -> #{custom_attributes}"
    #
    # ClientPepoCampaignDetail.get_from_memcache(GlobalConstant::TokenSale.st_token_sale_client_id)
    #     r = Email::Services::PepoCampaigns.new({}).add_contact(
    #       *add_update_contact_params
    #     )
    #
    #     puts "#{user.email} -> #{r}"
    #
    #   end
    #
    # end

  end

end

