class RestApi::SaasApi::V2::UsersKycdetailsController < ApplicationController

  # Get particular user kyc details for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    puts "inside UsersKycController : show"
    service_response = UserManagement::UserKyc::Get.new(params).perform
    format_response(service_response)
  end

  # Format response got from service.
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_response(service_response)
    formatted_response = service_response
    puts "Inside : format_response"

    if service_response.success?
      case params['action'].to_sym
      when :index
        formatted_response = Formatter::V2::Kyc.format_kyc(service_response)

      when :show
        puts "Inside : show : #{service_response.inspect}"
        formatted_response = Formatter::V2::Kyc.format_kyc(service_response)

      when :create
        puts "Inside : create : #{service_response.inspect}"
        formatted_response = Formatter::V2::Kyc.format_kyc(service_response)

      else
        fail "Formatter for action(#{params['action']}) did not written."
      end
    end

    puts "Final formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response)
  end
end