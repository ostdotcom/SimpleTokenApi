class ClientWhitelistDetail < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::ClientWhitelistDetail.active_status => 1,
           GlobalConstant::ClientWhitelistDetail.inactive_status => 2
       }

  enum suspension_type: {
      GlobalConstant::ClientWhitelistDetail.no_suspension_type => 0,
      GlobalConstant::ClientWhitelistDetail.low_balance_suspension_type => 1
  }, _suffix: true

  scope :not_suspended, -> {where(suspension_type: GlobalConstant::ClientWhitelistDetail.no_suspension_type)}

  after_commit :memcache_flush
  after_commit :update_subscription, if: :saved_change_to_contract_address?

  # Get Key Object
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('client.client_whitelist_details')
  end

  # Get/Set Memcache data for clients whitelist details
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] ClientWhitelistDetail object
  #
  def self.get_from_memcache(client_id)
    memcache_key_object = ClientWhitelistDetail.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {client_id: client_id}, memcache_key_object.expiry) do
      ClientWhitelistDetail.where(client_id: client_id).first
    end
  end

  # Mark eth balance of client is low
  #
  # * Author: Pankaj
  # * Date: 30/05/2018
  # * Reviewed By:
  #
  def mark_client_eth_balance_low
    self.suspension_type = GlobalConstant::ClientWhitelistDetail.low_balance_suspension_type
    self.save!

    # Send email to all admins
    admin_emails = Admin.client_admin_emails(self.client_id)

    admin_emails.each do |admin_email|
      Email::HookCreator::SendTransactionalMail.new(
          client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
          email: admin_email,
          template_name: GlobalConstant::PepoCampaigns.low_balance_whitelisting_suspended_template,
          template_vars: {whitelister_address: self.whitelister_address}
      ).perform

    end
  end

  # Get all active whitelist contract addresses
  #
  # * Author: Aniket
  # * Date: 07/08/2018
  # * Reviewed By:
  #
  def self.get_active_contract_addressess
    ClientWhitelistDetail.where(status:GlobalConstant::ClientWhitelistDetail.active_status).pluck(:contract_address)
  end


  # Mark whitelisting execution of client whitelist is reactive.
  #
  # * Author: Pankaj
  # * Date: 30/05/2018
  # * Reviewed By:
  #
  def mark_client_whitelist_happening
    self.suspension_type = GlobalConstant::ClientWhitelistDetail.no_suspension_type
    self.save!
  end

  private

  # Flush Memcache
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  def memcache_flush
    client_whitelist_details_memcache_key = ClientWhitelistDetail.get_memcache_key_object.key_template % {client_id: self.client_id}
    Memcache.delete(client_whitelist_details_memcache_key)
  end

  def update_subscription
    contract_addresses = ClientWhitelistDetail.where(status:GlobalConstant::ClientWhitelistDetail.active_status).pluck(:contract_address)
    BgJob.enqueue(
        UpdateWhitelist,
        {
            contract_addresses: contract_addresses
        }
    )
    Rails.logger.info("---- enqueue_job AutoApproveUpdateJob for ued_id-#{user_extended_details_id} done")
  end
end