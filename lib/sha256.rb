class Sha256

  # Initialize
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # @param [String] string
  # @param [String] salt
  #
  # @return [String] Digest
  #
  def initialize(params)
    @string = params[:string]
    @salt = params[:salt]
    @digest_byte_value = nil
  end

  # Perform
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # @return [String] Digest
  #
  def perform
    get_digest_using_salt
  end

  private

  # Get Digest
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # @return [String] Digest
  #
  def get_digest_using_salt
    get_digest_in_bytes
    digest_byte_value_to_hexadecimal
  end

  # Make 64 byte Digest
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # Sets @digest_byte_value
  #
  def get_digest_in_bytes
    hkdf_obj = HKDF.new(@string, salt: @salt, algorithm: 'SHA256')
    @digest_byte_value = hkdf_obj.next_bytes(64)
  end

  # Convert each byte to headecimal value
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  def digest_byte_value_to_hexadecimal
    @digest_byte_value.each_byte.map { |b| b.to_s(16) }.join
  end

end