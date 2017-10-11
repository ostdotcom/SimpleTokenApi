class ApplicationController < ActionController::API

  [
    # TODO: Do we need it for cookie support?
    #ActionController::Helpers, #This is added for cookies support
    ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  # Sanitize URL params
  include Sanitizer

  before_action :sanitize_params

  before_action :avoid_request_from_bot

  after_action :set_response_headers

  # Action not found handling. Also block "/"
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def not_found
    r = Result::Base.error({
                             error: 'ac_1',
                             error_message: 'Resource not found',
                             http_code: GlobalConstant::ErrorCode.not_found
                           })
    render_api_response(r)
  end

  private

  # Method for sanitizing params
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def sanitize_params
    sanitize_params_recursively(params)
  end

  # Block bot requests from consuming APIs
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def avoid_request_from_bot
    res = request.env['HTTP_USER_AGENT'].to_s.match(/\b(Baidu|Baiduspider|Gigabot|Googlebot|thefind|webmeup-crawler.com|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|ZIBB|wget|ia_archiver|ZyBorg|bingbot|AdsBot-Google|AhrefsBot|FatBot|shopstyle|pinterest.com|facebookexternalhit|Twitterbot|crawler.sistrix.net|PolyBot|rogerbot|Pingdom|Mediapartners-Google|bitlybot|BlapBot|Python|www.socialayer.com|Sogou|Scrapy|ShopWiki|Panopta|websitepulse|NewRelicPinger|Sailthru|JoeDog|SocialWire|CCBot|yacybot|Halebot|SNBot|SEOENGWorldBot|SeznamBot|libfetch|QuerySeekerSpider|A6-Indexer|PAYONE|GrapeshotCrawler|curl|ShowyouBot|NING|kraken|MaxPointCrawler|efcrawler|YisouSpider|BingPreview|MJ12bot)\b/i)
    if res.present?
      r = Result::Base.error({
                               error: 'ac_2',
                               error_message: 'Resource not found for Bot',
                               http_code: GlobalConstant::ErrorCode.not_found
                             })

      render_api_response(r)
    end
  end

  # Render API Response
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [Result::Base] service_response is an object of Result::Base class
  #
  def render_api_response(service_response)
    # calling to_json of Result::Base
    response_hash = service_response.to_json
    http_status_code = service_response.http_code

    # filter out not allowed http codes
    http_status_code = GlobalConstant::ErrorCode.ok unless GlobalConstant::ErrorCode.allowed_http_codes.include?(http_status_code)

    # sanitizing out error and data. only display_text and display_heading are allowed to be sent to FE.
    if !service_response.success? && !Rails.env.development?
      err = response_hash.delete(:err) || {}
      response_hash[:err] = {
        display_text: (err[:display_text] || 'Something went wrong.'),
        display_heading: (err[:display_heading] || 'Error'),
        error_data: (err[:error_data] || {})
      }

      response_hash[:data] = {}
    end

    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)
  end

  # After action for setting the response headers
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def set_response_headers
    response.headers["X-Robots-Tag"] = 'noindex, nofollow'
    response.headers["Content-Type"] = 'application/json; charset=utf-8'
  end

end
