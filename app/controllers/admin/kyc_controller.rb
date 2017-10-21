class Admin::KycController < Admin::BaseController

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
    service_response = AdminManagement::Kyc::Dashboard.new(params).perform
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
    service_response = AdminManagement::Kyc::AdminAction::DenyKyc.new(params).perform
    render_api_response(service_response)
  end

  # Admin found data mismatch
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def data_mismatch
    service_response = AdminManagement::Kyc::AdminAction::DataMismatch.new(params).perform
    render_api_response(service_response)
  end

  # Admin found passport improper
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def passport_issue
    service_response = AdminManagement::Kyc::AdminAction::PassportIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin found selfie improper
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def selfie_image_issue
    service_response = AdminManagement::Kyc::AdminAction::SelfieImageIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin found residency improper
  #
  # * Author: Alpesh
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def residency_image_issue
    service_response = AdminManagement::Kyc::AdminAction::ResidencyImageIssue.new(params).perform
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

end
