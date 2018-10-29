class RestApi::SaasApi::V2::UsersKycController < RestApi::SaasApi::V2::BaseController

  before_action do
    authenticate_request(true)
  end

  skip_before_action :authenticate_request

  # Get list of user kyc by pagination
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def index
    @service_response = UserManagement::Kyc::List.new(params).perform
    format_service_response
  end

  # Get particular user kyc for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    @service_response = UserManagement::Kyc::Get.new(params).perform
    format_service_response
  end

  # Create/Update user kyc for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def submit
    @service_response = UserManagement::Kyc::Submit.new(params).perform
    format_service_response
  end

  # Get pre_signed url for S3 put
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def get_pre_singed_url_for_put
    @service_response = UserManagement::DocumentsUploader::V2::ForPut.new(params).perform
    format_service_response
  end

  # Get pre_signed url for S3 post
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def get_pre_singed_url_for_post
    @service_response = UserManagement::DocumentsUploader::V2::ForPost.new(params).perform
    format_service_response
  end

  # Get formatter class
  #
  # * Author: Aniket
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_formatter_class
    Formatter::V2::UsersKyc
  end

end