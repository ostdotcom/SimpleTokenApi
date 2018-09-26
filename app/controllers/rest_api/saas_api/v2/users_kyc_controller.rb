class RestApi::SaasApi::V2::UsersKycController < ApplicationController #RestApi::SaasApi::V2::BaseController

  # Get list of user kyc by pagination
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def index
    puts "inside UsersKycController : index"
  end

  # Get particular user kyc for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    puts "inside UsersKycController : show"
    service_response = UserManagement::Kyc::Get.new(params).perform
    format_response(service_response)
  end

  # Create/Update user kyc for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def submit
    puts "inside UsersKycController : submit"

  end

  # Get pre_signed url for S3 put
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def get_pre_singed_url_for_put
    puts "inside UsersKycController : get_pre_singed_url_for_put"

    service_response = UserManagement::DocumentsUploader::SignedPutUrls.new(params).perform
    render_api_response(service_response)
  end

  # Get pre_signed url for S3 post
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def get_pre_singed_url_for_post
    puts "inside UsersKycController : get_pre_singed_url_for_post"

    service_response = UserManagement::DocumentsUploader::SignedPostParams.new(params).perform
    render_api_response(service_response)
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