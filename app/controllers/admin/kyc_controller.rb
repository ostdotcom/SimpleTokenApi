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
  # * Reviewed By:
  #
  def data_mismatch
    service_response = AdminManagement::Kyc::AdminAction::DataMismatch.new(params).perform
    render_api_response(service_response)
  end

  # Admin found passport improper
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By:
  #
  def passport_issue
    service_response = AdminManagement::Kyc::AdminAction::PassportIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin found selfie improper
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By:
  #
  def selfie_image_issue
    service_response = AdminManagement::Kyc::AdminAction::SelfieImageIssue.new(params).perform
    render_api_response(service_response)
  end

  # Admin qualified kyc
  #
  # * Author: Alpesh
  # * Date: 15/10/2017
  # * Reviewed By:
  #
  def qualify
    service_response = AdminManagement::Kyc::AdminAction::Qualify.new(params).perform
    render_api_response(service_response)
  end

end
