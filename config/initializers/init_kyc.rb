class InitKyc

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'kyc.ost.com'
    elsif Rails.env.sandbox?
      request.host == 'kyc.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'kyc.stagingsimpletoken.org'
    else
      request.host == 'kyc.developmentost.com'
    end
  end

end
