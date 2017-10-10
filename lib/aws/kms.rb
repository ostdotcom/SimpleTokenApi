module Aws

  class Kms

    include ::Util::ResultHelper

    def initialize(purpose, role)
      @purpose = purpose
      @role = role
    end

    def decrypt(ciphertext_blob)
      begin

        d_resp = client.decrypt({
                                  ciphertext_blob: ciphertext_blob
                                }).to_h

        plaintext = d_resp[:plaintext]

        return success_with_data(
          plaintext: plaintext
        )

      rescue => e
        return exception_with_action_and_data(
          e,
          'a_k_1',
          'exception in decrypt: ' + e.message,
          'Something went wrong.',
          GlobalConstant::ApiErrorAction.default,
          {
            role: @role,
            ciphertext_blob: ciphertext_blob
          }
        )
      end
    end

    def encrypt(plaintext)
      begin

        e_resp = client.encrypt({
                                  plaintext: plaintext,
                                  key_id: key_id
                                }).to_h

        ciphertext_blob = e_resp[:ciphertext_blob]

        return success_with_data(
          ciphertext_blob: ciphertext_blob
        )

      rescue => e
        return exception_with_action_and_data(
          e,
          'a_k_2',
          'exception in encrypt: ' + e.message,
          'Something went wrong.',
          GlobalConstant::ApiErrorAction.default,
          {
            role: @role,
            plaintext: plaintext
          }
        )
      end
    end

    private

    def client
      @client ||= Aws::KMS::Client.new(
        access_key_id: access_key_id,
        secret_access_key: secret_key,
        region: region
      )
    end

    def key_id
      GlobalConstant::Aws::Kms.get_key_id_for(@purpose)
    end

    def access_key_id
      config['access_key']
    end

    def secret_key
      config['secret_key']
    end

    def region
      GlobalConstant::Aws::Common.region
    end

    def config
      @config ||= GlobalConstant::Aws::Common.get_credentials_for(@role)
    end

  end

end