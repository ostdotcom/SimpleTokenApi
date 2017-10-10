class LocalCipher

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] key - the secret key to use for encryption
  #
  # @return [LocalCipher]
  #
  def initialize(key)
    @key = key
  end

  # Encrypt
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] plaintext - the plaintext to encrypt
  #
  # @return [Result::Base]
  #
  def encrypt(plaintext)
    ciphertext_blob = client.encrypt_and_sign(plaintext)

    success_with_data(
      ciphertext_blob: ciphertext_blob
    )
  end

  # Decrypt
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [String] ciphertext_blob - the ciphertext blob to decrypt
  #
  # @return [Result::Base]
  #
  def decrypt(ciphertext_blob)
    plaintext = client.decrypt_and_verify(ciphertext_blob)

    success_with_data(
      plaintext: plaintext
    )
  end

  private

  # Client
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @param [ActiveSupport::MessageEncryptor]
  #
  def client
    @client ||= ActiveSupport::MessageEncryptor.new(@key, cipher: 'aes-256-cbc')
  end

end