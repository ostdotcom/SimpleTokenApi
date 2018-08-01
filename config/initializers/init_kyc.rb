class InitKyc

  def self.matches?(request)
    puts "REQUEST-#{request.host}"

    if Rails.env.production?
      request.host == 'kyc.ost.com'
    elsif Rails.env.sandbox?
      request.host == 'kyc.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'kyc.stagingost.com'
    else
      true #request.host == 'kyc.developmentost.com'
    end
  end

end
