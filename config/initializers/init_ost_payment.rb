class InitOstPayment

  def self.matches?(request)
    if Rails.env.production?
      request.host == 'payment.ost.com'
    elsif Rails.env.sandbox?
      false #&& request.host == 'sale.sandboxost.com'
    elsif Rails.env.staging?
      request.host == 'payment.stagingost.com'
    else
      request.host == 'payment.developmentost.com'
    end
  end

end
