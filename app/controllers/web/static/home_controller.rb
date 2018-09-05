class Web::Static::HomeController < Web::Static::BaseController

  before_action :verify_recaptcha

  prepend_before_action :merge_utm_to_params, only: [:contact_us_pipe_drive_kyc]

  #
  # * Author: Santhosh
  # * Date: 21/05/2018
  # * Reviewed By:
  #
  def contact_us_pipe_drive_kyc
    service_response = UserManagement::ContactUsPipeDrive::Kyc.new(params).perform
    render_api_response(service_response)
  end

  #
  # * Author: Santhosh
  # * Date: 21/05/2018
  # * Reviewed By:
  #
  def contact_us_partners_pipe_drive
    service_response = UserManagement::ContactUsPipeDrive::Partner.new(params).perform
    render_api_response(service_response)
  end

  # Register user for Alpha 4
  #
  # * Author: Tejas
  # * Date: 23/08/2018
  # * Reviewed By:
  #
  def register_for_alpha4
    service_response = UserManagement::Alpha4Registration.new(params).perform
    render_api_response(service_response)
  end

end
