class Web::Admin::KycController < Web::Admin::BaseController

  # super admin
  before_action :authenticate_request

  # super admin
  before_action :merge_client_to_params

  include ::Util::ResultHelper

  # Check details
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil
  #
  def check_details
    service_response = AdminManagement::Kyc::CheckDetails.new(params).perform
    render_api_response(service_response)
  end

  # Dashboard
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil
  #
  def dashboard
    service_response = AdminManagement::Kyc::Dashboard::Status.new(params).perform
    render_api_response(service_response)
  end

  # Fetch duplicate
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil
  #
  def fetch_duplicate
    service_response = AdminManagement::Kyc::FetchDuplicates.new(params).perform
    render_api_response(service_response)
  end

  # Deny KYC by admin
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def deny_kyc
    service_response = AdminManagement::Kyc::AdminAction::DenyCase.new(params).perform
    render_api_response(service_response)
  end

  # Email Admin found kyc data issue
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def email_kyc_issue
    service_response = AdminManagement::Kyc::AdminAction::ReportIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin approve details before aml processing
  #
  # * Author: Mayur
  # * Date: 11/01/2019
  # * Reviewed By:
  #
  def approve_details
    service_response = AdminManagement::Kyc::AdminAction::ApproveDetails.new(params).perform
    render_api_response(service_response)
  end

  # Admin approve case
  #
  # * Author: Mayur
  # * Date: 11/01/2019
  # * Reviewed By:
  #
  def approve_case
    service_response = AdminManagement::Kyc::AdminAction::ApproveCase.new(params).perform
    render_api_response(service_response)
  end

  # Fetch admin kyc action logs.
  #
  # * Author: Alpesh
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def kyc_action_logs
    service_response = AdminManagement::Kyc::FetchActionLogs.new(params).perform
    render_api_response(service_response)
  end

  # Get cases by email address.
  #
  # * Author: Alpesh
  # * Date: 20/11/2017
  # * Reviewed By:
  #
  def get_cases_by_email
    service_response = AdminManagement::Kyc::GetByEmail.new(params).perform
    render_api_response(service_response)
  end

  # Open Edit KYC case
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  def open_kyc_case
    service_response = AdminManagement::Kyc::OpenEditKycCase.new(params).perform
    render_api_response(service_response)
  end

  # Update Ethereum address of Open KYC case
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  def update_ethereum_address
    service_response = AdminManagement::Kyc::UpdateEthereumAddress.new(params).perform
    render_api_response(service_response)
  end

  private

  # merge client obj to params and validate if active
  #
  # * Author: Aman
  # * Date: 25/01/2019
  # * Reviewed By:
  #
  #
  def merge_client_to_params
    client = Client.get_from_memcache(params[:client_id])
    params[:client] = client

    if client.blank? || client.status != GlobalConstant::Client.active_status
      error_with_identifier('invalid_client_id','w_a_kc_mctp_1')
      render_api_response(service_response)
    end

  end

end
