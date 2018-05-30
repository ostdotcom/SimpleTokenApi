class InitKyc

  def self.matches?(request)
    if Rails.env.production?
      ['kyc.ost.com', 'eukyc.ost.com', 'euroutekyc.ost.com'].include?(request.host)
    elsif Rails.env.sandbox?
      request.host == 'kyc.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'kyc.stagingost.com'
    else
      request.host == 'kyc.developmentost.com'
    end
  end

end
