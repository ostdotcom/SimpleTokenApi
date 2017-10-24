class User < EstablishSimpleTokenUserDbConnection

  enum status: {
           GlobalConstant::User.active_status => 1,
           GlobalConstant::User.inactive_status => 2,
           GlobalConstant::User.deactived_status => 3
       }

  # Array of Properties symbols
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  # @returns [Array<Symbol>] returns Array of properties bits set for user
  #
  def properties_array
    @properties_array = User.get_bits_set_for_properties(properties)
  end

  # Get Token Sale Landing Page
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  # @returns [String] returns page name according to user properties
  #
  def get_token_sale_state_page_name
    if properties_array.include?(GlobalConstant::User.token_sale_double_optin_done_property)
      GlobalConstant::User.get_token_sale_state_page_names("profile_page")
    elsif properties_array.include?(GlobalConstant::User.token_sale_bt_done_property)
      GlobalConstant::User.get_token_sale_state_page_names("verification_page")
    elsif properties_array.include?(GlobalConstant::User.token_sale_kyc_submitted_property)
      GlobalConstant::User.get_token_sale_state_page_names("bt_page")
    else
      GlobalConstant::User.get_token_sale_state_page_names("kyc_page")
    end
  end

  # properties config
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def self.properties_config
    @u_prop_con ||= {
        GlobalConstant::User.token_sale_kyc_submitted_property => 1,
        GlobalConstant::User.token_sale_bt_done_property => 2,
        GlobalConstant::User.token_sale_double_optin_mail_sent_property => 4,
        GlobalConstant::User.token_sale_double_optin_done_property => 8
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        properties: properties_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  # Get encrypted password
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [String] password
  # @param [String] salt
  #
  # @return [String] MD5 Encrypted password
  #
  def self.get_encrypted_password(password, salt)
    Digest::MD5.hexdigest("#{password}::#{salt}")
  end

  # Get cookie value
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Integer] user_id - user id
  # @param [String] password - password
  # @param [String] browser_user_agent - user browser agent
  #
  # @return [String] cookie value
  #
  def self.get_cookie_value(user_id, password, browser_user_agent)
    current_ts = Time.now.to_i
    token_e = get_cookie_token(user_id, password, browser_user_agent, current_ts)
    "#{user_id}:#{current_ts}:#{GlobalConstant::Cookie.double_auth_prefix}:#{token_e}"
  end

  # Get cookie token
  #
  # * Author: Aman
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Integer] user_id - user id
  # @param [String] password - password
  # @param [String] browser_user_agent - user browser agent
  # @param [Integer] current_ts - current timestamp
  #
  # @return [String] cookie value
  #
  def self.get_cookie_token(user_id, password, browser_user_agent, current_ts)
    string_to_sign = "#{user_id}:#{password}:#{browser_user_agent}:#{current_ts}:#{GlobalConstant::Cookie.double_auth_prefix}"
    key="#{user_id}:#{current_ts}:#{browser_user_agent}:#{password[-12..-1]}:#{GlobalConstant::SecretEncryptor.cookie_key}"
    hkdf = HKDF.new(string_to_sign, :salt => key, :algorithm => 'SHA256')
    val = hkdf.next_bytes(64)
    val.each_byte.map { |b| b.to_s(16) }.join
  end

end