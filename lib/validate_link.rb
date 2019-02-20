class ValidateLink

  class << self

    def is_valid_redirect_path?(url)
      uri = URI.parse(url)
    rescue
       return false
    else
      uri.host.blank? && !url.match(valid_redirect_path_regex).nil?
    end

    def valid_redirect_path_regex
      /\A\/[A-Z0-9\-\_\/]+(\?[A-Z0-9\-\_\/\&\=\.\[\]\+\#\?\@\!\']*)?\z/i
    end
  end
end