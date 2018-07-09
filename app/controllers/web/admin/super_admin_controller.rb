class Web::Admin::SuperAdminController < Web::Admin::BaseController

  before_action only: [:get_kyc_report, :invite, :resend_invite, :reset_mfa, :delete_admin] do
    authenticate_request(true)
  end

  before_action :authenticate_request, only: [:dashboard]

  # Note: Can be accessed by all admins


  # Dashboard
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def dashboard
    service_response = AdminManagement::AdminUser::Dashboard.new(params).perform
    render_api_response(service_response)
  end


  # Note: Can only be accessed by superadmins

  # enqueue a job to send csv with kyc details
  #
  # * Author: Aman
  # * Date: 18/04/2018
  # * Reviewed By:
  #
  def get_kyc_report
    service_response = AdminManagement::Report::GetKycReport.new(params).perform
    render_api_response(service_response)
  end

  # Send Invite to admin user
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def invite
    service_response = AdminManagement::AdminUser::Invite::Send.new(params).perform
    render_api_response(service_response)
  end

  # Resend Invite to admin user
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def resend_invite
    service_response = AdminManagement::AdminUser::Invite::Resend.new(params).perform
    render_api_response(service_response)
  end

  # Reset MFA code of admin user
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def reset_mfa
    service_response = AdminManagement::AdminUser::ResetMfa.new(params).perform
    render_api_response(service_response)
  end

  # Soft delete an admin
  #
  # * Author: Aman
  # * Date: 03/05/2018
  # * Reviewed By:
  #
  def delete_admin
    service_response = AdminManagement::AdminUser::DeleteAdmin.new(params).perform
    render_api_response(service_response)
  end



end