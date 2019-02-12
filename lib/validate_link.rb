class ValidateLink

  class << self

    def is_valid?(url)
      !url.match(valid_url_regex).nil?
    end

    def valid_url_regex
      /\A[a-zA-Z0-9\-_.~:\/?#\[\]@!$'()+*,;=]*\z/
    end
  end
end