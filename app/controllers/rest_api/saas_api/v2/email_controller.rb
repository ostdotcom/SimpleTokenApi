class RestApi::SaasApi::V2::EmailController < RestApi::SaasApi::V2::BaseController
  def email_kyc_approve
    @service_response = UserManagement::EmailKycStatus::Approve.new(params).perform

  end
end