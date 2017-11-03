namespace :onetimer do

  # rake RAILS_ENV=development onetimer:repopulate_user_attributes_in_email_service

  task :repopulate_user_attributes_in_email_service => :environment do

    User.where(status: GlobalConstant::User.active_status).find_in_batches do |batched_users|

      batched_users.each do |user|

        custom_attributes = {
          GlobalConstant::PepoCampaigns.token_sale_registered_attribute => GlobalConstant::PepoCampaigns.token_sale_registered_value
        }

        if user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")
          custom_attributes[GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_attribute] = GlobalConstant::PepoCampaigns.token_sale_kyc_confirmed_value
        end

        Email::HookCreator::AddContact.new(
          email: user.email,
          custom_attributes: custom_attributes
        ).perform

      end

    end

  end

end

