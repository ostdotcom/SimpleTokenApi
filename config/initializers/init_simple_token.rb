class InitSimpleToken

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'simpletoken.org'
    elsif Rails.env.sandbox?
      false #&& request.host == 'sale.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'stagingsimpletoken.org'
    else
      request.host == 'developmentsimpletoken.org'
    end
  end

end
