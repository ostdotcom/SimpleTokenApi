class Callback::BaseController < ApiController

  skip_before_action :validate_cookie
  # skip_before_action :verify_authenticity_token

end