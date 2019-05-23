class InitOstPaymentClient

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'payment.ostclient.com'
    elsif Rails.env.sandbox?
      false #&& request.host == 'sale.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'payment.stagingostclient.com'
    else
      request.host == 'payment.developmentostclient.com'
    end
  end

end
