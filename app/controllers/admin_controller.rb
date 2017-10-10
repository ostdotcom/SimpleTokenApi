class AdminController < ApiController

  before_action :validate_cookie, except: [
    :password_auth
  ]

  def password_auth

  end

  def multifactor_auth

  end


end
