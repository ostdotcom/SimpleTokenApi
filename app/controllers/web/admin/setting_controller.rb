class Web::Admin::SettingController < Web::Admin::BaseController

  before_action only: [:reset_api_credentials, :update_api_fields, :get_developer_detail, :update_contract_address,
                        :update_whitelist_address, :get_contract_addresses] do
    authenticate_request(true)
  end

  # Reset Api Credentials
  #
  # * Author: Tejas
  # * Date: 27/08/2018
  # * Reviewed By:
  #
  def reset_api_credentials
    service_response = ClientManagement::ResetApiCredentials.new(params).perform
    render_api_response(service_response)
  end

  # Update Api Fields
  #
  # * Author: Tejas
  # * Date: 27/08/2018
  # * Reviewed By:
  #
  def update_api_fields
    service_response = ClientManagement::UpdateApiFields.new(params).perform
    render_api_response(service_response)
  end

  # get Developer Detail
  #
  # * Author: Aniket
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def get_developer_detail
    service_response = ClientManagement::DeveloperDetail.new(params).perform
    render_api_response(service_response)
  end

  # Update Deposit Address
  #
  # * Author: Aniket
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def update_deposit_address
    service_response = ClientManagement::UpdateDepositAddress.new(params).perform
    render_api_response(service_response)
  end

  # Update Whitelist Address
  #
  # * Author: Aniket
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def update_whitelist_address
    service_response = ClientManagement::UpdateWhitelistAddress.new(params).perform
    render_api_response(service_response)
  end

  # Get Contract Addresses
  #
  # * Author: Aniket
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def get_contract_addresses
    service_response = ClientManagement::GetContractAddresses.new(params).perform
    render_api_response(service_response)
  end

end