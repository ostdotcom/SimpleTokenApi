class Md5UserExtendedDetail < EstablishSimpleTokenUserDbConnection

  # Encrypt by sha256 algorithm
  #
  # * Author: Aman
  # * Date: 30/10/2017
  # * Reviewed By: Abhay
  #
  # str [String] String to be hash
  #
  # Returns[String] sha256 encrypted value
  #
  def self.get_hashed_value(str)
    Sha256.new(
        {
            string: str.to_s.downcase.strip,
            salt: GlobalConstant::SecretEncryptor.user_extended_detail_secret_key
        }
    ).perform
  end

end
