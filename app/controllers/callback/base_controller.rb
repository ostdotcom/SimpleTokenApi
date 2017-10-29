class Callback::BaseController < ApiController

  skip_before_action :validate_cookie

end