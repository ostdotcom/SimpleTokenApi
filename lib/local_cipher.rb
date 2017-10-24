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
    begin
      ciphertext_blob = client.encrypt_and_sign(plaintext)

      success_with_data(
          ciphertext_blob: ciphertext_blob
      )
    rescue Exception => e
      error_with_data('lc_1',
                      "LocalCipher could not encrypt text with message => #{e.message}",
                      'Something Went Wrong.',
                      GlobalConstant::ErrorAction.default,
                      {})
    end
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
    begin
      plaintext = client.decrypt_and_verify(ciphertext_blob)

      success_with_data(
          plaintext: plaintext
      )
    rescue Exception => e
      error_with_data('lc_2',
                      "LocalCipher could not decrypt cipher with message => #{e.message}",
                      'Something Went Wrong.',
                      GlobalConstant::ErrorAction.default,
                      {})
    end
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