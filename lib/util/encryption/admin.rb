module Util
  module Encryption

    class Admin

      # decrypt string and encrypt by sha256 algorithm
      #
      # * Author: Aman
      # * Date: 30/10/2017
      # * Reviewed By: Abhay
      #
      # kyc_salt_e [String] KMS Encrypted Salt
      # plaintext [String] 2 way locally encrypted string
      #
      # Returns[String] sha256 one-way encrypted value
      #
      def self.get_sha256_hashed_value_from_kms_encrypted_value(kyc_salt_e, ciphertext_blob)
        r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
        fail "decryption of kyc salt failed. for salt- #{kyc_salt_e}" unless r.success?
        kyc_salt_d = r.data[:plaintext]
        decryptor_obj = LocalCipher.new(kyc_salt_d)
        r = decryptor_obj.decrypt(ciphertext_blob)
        fail "local cipher decryption of string failed for salt- #{kyc_salt_e}, string-#{ciphertext_blob}" unless r.success?
        Md5UserExtendedDetail.get_hashed_value(r.data[:plaintext])
      end

      # Get Uuid
      #
      # * Author: Aniket
      # * Date: 09/08/2018
      # * Reviewed By:
      #
      def self.get_uuid
        rand_no = rand.to_s[2..6].to_s #generate 5 digit random string
        timestamp = Time.now.to_f.to_s

        Digest::SHA256.hexdigest(rand_no + '-' + timestamp)
      end

    end
  end
end
