class InitKyc

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'kyc.ost.com'
    elsif Rails.env.staging?
      request.host == 'kyc.stagingost.com'
    else
      request.host == 'kyc.developmentost.com'
    end
  end

end
