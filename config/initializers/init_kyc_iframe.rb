class InitKycIframe

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'iframekyc.ost.com'
    elsif Rails.env.sandbox?
      request.host == 'iframekyc.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'iframekyc.stagingost.com'
    else
      request.host == 'iframekyc.developmentost.com'
    end
  end

end