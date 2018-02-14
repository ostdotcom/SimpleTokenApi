class Web::SaasUser::ProfileController < Web::SaasUser::BaseController

  skip_before_action :authenticate_request, only: [:client_detail]

  # Get logged in user details
  #
  # * Author: Aman
  # * Date: 09/02/2018
  # * Reviewed By:
  #
  def client_detail
    puts "\n\n\n\n\n"
    puts params[:controller]
    service_response = UserManagement::GetClientDetail.new(params).perform
    render_api_response(service_response)
  end

  # Get logged in user details
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def basic_detail
    service_response = UserManagement::GetBasicDetail.new(params).perform
    render_api_response(service_response)
  end

  # Get profile info and validate double opt in token if present
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def profile
    service_response = UserManagement::ProfileDetail.new(params).perform
    render_api_response(service_response)
  end

  # Get ethereum address if eligible for address
  #
  # * Author: Aman
  # * Date: 27/10/2017
  # * Reviewed By: Sunil
  #
  def get_token_sale_address
    service_response = UserManagement::GetTokenSaleAddress.new(params).perform
    render_api_response(service_response)
  end

end
