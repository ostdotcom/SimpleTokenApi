# Note: This class is used for sending unmodified headers for Acuris Api using HttpHelper::HttpRequest
class CaseSensitiveString < String
  def downcase
    self
  end

  def capitalize
    self
  end

  def to_s
    self
  end
end

