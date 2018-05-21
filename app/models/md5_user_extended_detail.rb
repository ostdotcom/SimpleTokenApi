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

  # Get active recors object from unencrypted ethereum address
  #
  # * Author: Alpesh
  # * Date: 14/11/2017
  # * Reviewed By:
  #
  # str [String] Unencypted ethereum address,
  #
  # Returns[Integer] user id .
  #
  def self.get_user_id(client_id, ethereum_address)

    sha_ethereum = get_hashed_value(ethereum_address)

    ued_ids = Md5UserExtendedDetail.where(ethereum_address: sha_ethereum).pluck(:user_extended_detail_id)

    UserKycDetail.where(client_id: client_id, user_extended_detail_id: ued_ids).kyc_admin_and_cynopsis_approved.first.user_id
  end

end
