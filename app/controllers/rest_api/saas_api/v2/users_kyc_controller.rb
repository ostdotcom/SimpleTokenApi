class RestApi::SaasApi::V2::UsersKycController < RestApi::SaasApi::V2::BaseController

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
    puts "Inside : format_response : #{service_response.inspect}"

    if service_response.success?
      formatted_response = Formatter::V2::UsersKyc.send(params['action'], service_response)
    end

    puts "Final formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response)
  end

end