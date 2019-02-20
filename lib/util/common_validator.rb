module Util
  class CommonValidator


    # Should Email be send to this email & this env
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_email_send_allowed?(email)
      return false unless Util::CommonValidateAndSanitize.is_valid_email?(email)
      Rails.env.production? || [
          ''
      ].include?(email)
    end

    # check if the addr is a valid address
    #
    # * Author: Kedar
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_ethereum_address?(addr)
      !(/^(0x|0X)?[a-fA-F0-9]{40}$/.match(addr.to_s)).nil?
    end

    # Sanitize Ethereum Address
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [String] returns sanitized ethereum address
    #
    def self.sanitize_ethereum_address(address)
      ethereum_address = address.to_s.strip
      if (!ethereum_address.start_with?('0x') && !ethereum_address.start_with?('0X'))
        ethereum_address = '0x' + ethereum_address
      end
      ethereum_address
    end

    # Escape Regex
    #
    # * Author: Tejas
    # * Date: 11/12/2018
    # * Reviewed By:
    #
    # @return [String] returns escaped regex string
    #
    def self.escape_regex(string)
      return Regexp.quote(string)
    end

  end

end
