# frozen_string_literal: true
module GlobalConstant

  class SecretEncryptor

    class << self

      def cookie_key
        GlobalConstant::Base.secret_encryptor['cookie_secret_key']
      end

      def email_tokens_key
        GlobalConstant::Base.secret_encryptor['email_tokens_decriptor_key']
      end

      def user_extended_detail_secret_key
        GlobalConstant::Base.secret_encryptor['user_extended_detail_secret_key']
      end

      def ethereum_deposit_address_secret_key
        GlobalConstant::Base.secret_encryptor['ethereum_deposit_address_secret_key']
      end

      def webhook_event_secret_key
        GlobalConstant::Base.secret_encryptor['webhook_event_secret_key']
      end

      def memcache_encryption_key
        GlobalConstant::Base.secret_encryptor['memcache_encryption_key']
      end

    end

  end

end
