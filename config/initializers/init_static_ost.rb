class InitStaticOst

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'static.ost.com'
    elsif Rails.env.sandbox?
      request.host == 'static.stagingost.com'
    elsif Rails.env.staging?
      request.host == 'static.stagingost.com'
    else
      request.host == 'static.developmentost.com'
    end
  end

end
