class Md5UserExtendedDetail

  module Methods
    extend ActiveSupport::Concern

    included do

    end


    module ClassMethods

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
      def get_hashed_value(str)
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
      def get_user_id(client_id, ethereum_address)
        ukds = get_user_kyc_details(client_id, ethereum_address)

        ukds.first.user_id
      end

      # Get active qualified user kyc detail objects from unencrypted ethereum address
      #
      # * Author: Aman
      # * Date: 4/06/2018
      # * Reviewed By:
      #
      # str [String] Unencypted ethereum address,
      #
      # Returns[Array] USer Kyc Details objects.
      #
      def get_user_kyc_details(client_id, ethereum_address)
        return [] if ethereum_address.blank?

        sha_ethereum = get_hashed_value(ethereum_address)

        ued_ids = self.where(ethereum_address: sha_ethereum).pluck(:user_extended_detail_id)
        return [] if ued_ids.blank?

        UserKycDetail.using_shard(shard_identifier: self.shard_identifier).
            where(client_id: client_id, user_extended_detail_id: ued_ids).kyc_admin_and_aml_approved.all
      end

    end

  end

end
