class RestApi::SaasApi::V2::UsersKycController < ApplicationController#RestApi::SaasApi::V2::BaseController

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
end