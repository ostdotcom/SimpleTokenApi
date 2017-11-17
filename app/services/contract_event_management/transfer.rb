module ContractEventManagement

  class Transfer < Base

    # initialize
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [ContractEventManagement::Transfer]
    #
    def initialize(params)
      super

      @block_creation_timestamp = @params[:block_creation_timestamp]

      @ethereum_address, @ether_value, @usd_value, @st_wei_value = nil, nil, nil, nil

      @user = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def perform

      _perform do

        sanitize_event_data

        create_purchase_log_entry

        get_user_from_ethereum

        update_purchase_attribute_in_pepo_campaigns

        send_purchase_confirmation_email

      end

    end

    private

    # Sanitize event_variables in an event
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Sets [@ethereum_address, @ether_wei_value, @usd_value, @st_wei_value]
    #
    def sanitize_event_data
      @contract_event_obj.data[:event_data].each do |var_obj|

        case var_obj[:name]
          when '_beneficiary'
            @ethereum_address = var_obj[:value].to_s
          when '_cost'
            @ether_wei_value = var_obj[:value].to_i
          when '_tokens'
            @st_wei_value = var_obj[:value].to_i
            @usd_value = GlobalConstant::ConversionRate.st_in_wei_to_usd(@st_wei_value).round(2)
        end

      end

    end

    # Create entry in payment details for ethereum
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def create_purchase_log_entry
      PurchaseLog.create!({
                              ethereum_address: @ethereum_address,
                              ether_wei_value: @ether_wei_value,
                              usd_value: @usd_value,
                              st_wei_value: @st_wei_value,
                              block_creation_timestamp: @block_creation_timestamp,
                              pst_day_start_timestamp: get_pst_rounded_purchase_date

                          })
    end

    # Get user from ethereum address.
    #
    # * Author: Alpesh
    # * Date: 14/11/2017
    # * Reviewed By: Sunil
    #
    def get_user_from_ethereum
      user_id = Md5UserExtendedDetail.get_user_id(@ethereum_address)
      @user = User.get_from_memcache(user_id)
    end

    # Update has_purchased attributes in pepo campaigns
    #
    # * Author: Aman
    # * Date: 16/11/2017
    # * Reviewed By: Sunil
    #
    def update_purchase_attribute_in_pepo_campaigns
      r = Email::Services::PepoCampaigns.new.update_contact(
          GlobalConstant::PepoCampaigns.master_list_id,
          @user.email,
          attributes_to_update
      )
      update_purchase_attribute_in_pepo_campaigns_via_hooks if r['error'].present?
    end

    # Attributes to update in pepo campaign
    #
    # * Author: Aman
    # * Date: 16/11/2017
    # * Reviewed By: Sunil
    #
    def attributes_to_update
      {
          GlobalConstant::PepoCampaigns.token_sale_has_purchased_attribute =>
              GlobalConstant::PepoCampaigns.token_sale_has_purchased_value
      }
    end

    # Update has_purchased attributes in pepo campaigns via hook processor
    #
    # * Author: Aman
    # * Date: 16/11/2017
    # * Reviewed By: Sunil
    #
    def update_purchase_attribute_in_pepo_campaigns_via_hooks
      Email::HookCreator::UpdateContact.new(
          email: @user.email,
          custom_attributes: attributes_to_update
      ).perform
    end

    # Send Email for the purchase confirmation
    #
    # * Author: Alpesh
    # * Date: 14/11/2017
    # * Reviewed By: Sunil
    #
    def send_purchase_confirmation_email
      return if @user.blank?

      send_mail_response = Email::Services::PepoCampaigns.new.send_transactional_email(
          @user.email, GlobalConstant::PepoCampaigns.purchase_confirmation, {})

      send_purchase_confirmation_email_via_hooks if send_mail_response['error'].present?
    end

    # Send Email via hook processor
    #
    # * Author: Alpesh
    # * Date: 14/11/2017
    # * Reviewed By: Sunil
    #
    def send_purchase_confirmation_email_via_hooks

      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.purchase_confirmation,
          template_vars: {}
      ).perform
    end

    # get rounded purchase date
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Date] purchase date in pactific time zone
    #
    def get_pst_rounded_purchase_date
      Time.at(@block_creation_timestamp).in_time_zone('Pacific Time (US & Canada)').beginning_of_day.to_i
    end

  end

end