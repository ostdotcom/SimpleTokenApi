module UserManagement

  class SignUp < ServicesBase

    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
    end

  end

end