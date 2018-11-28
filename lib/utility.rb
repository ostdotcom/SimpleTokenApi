class Utility

  # Genererate a unique UUID
  #
  # * Author: Puneet
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [String] suffix - suffix which you want to add to the randomly generated unique id
  #
  # @return [String] returns a string
  #
  def self.generate_random_id(suffix = nil)
    s = SecureRandom.hex(16)
    s = "#{s}_#{suffix.to_s}" if suffix.present?
    s
  end

end