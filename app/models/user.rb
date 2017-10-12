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
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of properties bits set for user
  #
  def properties_array
    @properties_array ||= User.get_bits_set_for_properties(properties)
  end

  # properties config
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By:
  #
  def self.properties_config
    @u_prop_con ||= {
        GlobalConstant::User.token_sale_kyc_submitted_property => 1,
        GlobalConstant::User.token_sale_bt_done_property => 2,
        GlobalConstant::User.token_sale_double_optin_mail_sent_property => 3,
        GlobalConstant::User.token_sale_double_optin_done_property => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 11/10/2017
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        properties: properties_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  ########################## Class Methods #########################



  def self.cookie_value(user, user_secret, browser_user_agent)
    current_ts = Time.now.to_i

    token_e = cookie_token(user.id, user.password, user_secret.id, browser_user_agent, current_ts)

    "#{user.id}:#{current_ts}:d:#{token_e}"
  end

  def self.cookie_token(user_id, password, user_secret_id, browser_user_agent, current_ts)
    Digest::MD5.hexdigest(
      "#{user_id}:#{password}:#{user_secret_id}:#{browser_user_agent}:#{current_ts}:d"
    )
  end

end
