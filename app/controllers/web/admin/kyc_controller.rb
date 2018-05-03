class Web::Admin::KycController < Web::Admin::BaseController

  # super admin
  before_action :authenticate_request

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

  # Run Pos Bonus Approval process in resque
  #
  # * Author: Aman
  # * Date: 29/10/2017
  # * Reviewed By: Sunil
  #
  # def run_pos_bonus_process
  #   BgJob.enqueue(
  #       BonusApproval::PosBonusApprovalJob,
  #     {
  #         bonus_file_name: 'mark_pos_with_email.csv'
  #     }
  #   )
  #
  #   r = Result::Base.success({})
  #   render_api_response(r)
  # end

  # Run Alt token Approval process in resque
  #
  # * Author: Aman
  # * Date: 06/11/2017
  # * Reviewed By: Sunil
  #
  # def run_alt_token_bonus_process
  #   BgJob.enqueue(
  #       BonusApproval::AltTokenBonusApprovalJob,
  #       {
  #           bonus_file_name: 'mark_alternate_token_with_email.csv'
  #       }
  #   )
  #
  #   r = Result::Base.success({})
  #   render_api_response(r)
  # end

  # Whitelist Dashboard
  #
  # * Author: Alpesh
  # * Date: 14/10/2017
  # * Reviewed By: Sunil
  #
  # def whitelist_dashboard
  #   service_response = AdminManagement::Kyc::Dashboard::Whitelist.new(params).perform
  #   render_api_response(service_response)
  # end

  # Sale All Dashboard
  #
  # * Author: Alpesh
  # * Date: 09/11/2017
  # * Reviewed By: Sunil
  #
  # def sale_all_dashboard
  #   service_response = AdminManagement::Kyc::Dashboard::SaleAll.new(params).perform
  #   render_api_response(service_response)
  # end

  # Sale Day wise Dashboard
  #
  # * Author: Alpesh
  # * Date: 09/11/2017
  # * Reviewed By: Sunil
  #
  # def sale_daily_dashboard
  #   service_response = AdminManagement::Kyc::Dashboard::SaleDaily.new(params).perform
  #   render_api_response(service_response)
  # end

  # Contract Events Dashboard
  #
  # * Author: Alpesh
  # * Date: 10/11/2017
  # * Reviewed By:
  #
  # def contract_events_dashboard
  #   service_response = AdminManagement::Kyc::Dashboard::ContractEvents.new(params).perform
  #   render_api_response(service_response)
  # end

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
    service_response = AdminManagement::Kyc::AdminAction::DenyKyc.new(params).perform
    render_api_response(service_response)
  end

  # Email Admin found kyc data issue
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def email_kyc_issue
    service_response = AdminManagement::Kyc::AdminAction::EmailKycIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin qualified kyc
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def qualify
    service_response = AdminManagement::Kyc::AdminAction::Qualify.new(params).perform
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

  # Change ethereum address and open the case.
  #
  # * Author: Alpesh
  # * Date: 20/11/2017
  # * Reviewed By:
  #
  def change_address_and_open_case
    service_response = AdminManagement::Kyc::ChangeAddressAndOpenCase.new(params).perform
    render_api_response(service_response)
  end

  # Add Udate Kyc Detail in cynopsis in case of failure
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  def retry_cynopsis_upload
    service_response = AdminManagement::Kyc::RetryCynopsisUpload.new(params).perform
    render_api_response(service_response)
  end

end
