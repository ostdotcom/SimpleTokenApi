module ClientManagement

  class Base < ServicesBase

    def initialize(params)
      super
    end

    private

    def perform
      self.api_key = SecureRandom.hex
      self.api_secret = SecureRandom.hex
    end




  end

end