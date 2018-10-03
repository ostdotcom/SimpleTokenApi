class User < EstablishSimpleTokenUserDbConnection

  enum status: {
      GlobalConstant::User.active_status => 1,
      GlobalConstant::User.inactive_status => 2,
      GlobalConstant::User.deleted_status => 3
  }

  scope :sorting_by, -> (sortings) {
    order_clause = {}
    # This sorting is also used in user kyc detail.
    sortings.each do |key, val|
      sort_data = GlobalConstant::User.sorting[key.to_s][val.to_s]
      order_clause.merge!(sort_data) if sort_data.present?
    end
    order(order_clause)
  }

  scope :is_active, -> {where(status: GlobalConstant::User.active_status)}

  #:NOTE fails if filter passed with key 'all', needs to test if all key is added.
  # inconsistent behaviour was seen when no filter was applicable
  scope :filter_by, -> (filters) {
    where_clause = []
    filters.each do |key, val|
      if key.to_s === GlobalConstant::User.email_filter
        where_clause << ["email like ?", "#{val}%"]
      else
        where_clause << GlobalConstant::User.filters[key.to_s][val.to_s] if GlobalConstant::User.filters[key.to_s][val.to_s].present?
      end
    end

    return if where_clause.blank?

    ar = self
    where_clause.each do |clause|
      ar = ar.where(clause)
    end

    ar
  }

  after_commit :memcache_flush

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

    if (self.client_id == GlobalConstant::TokenSale.st_token_sale_client_id)

      if properties_array.include?(GlobalConstant::User.token_sale_double_optin_done_property)
        GlobalConstant::User.get_token_sale_state_page_names("profile_page")
      elsif properties_array.include?(GlobalConstant::User.token_sale_kyc_submitted_property)
        GlobalConstant::User.get_token_sale_state_page_names("verification_page")
      else
        GlobalConstant::User.get_token_sale_state_page_names("kyc_page")
      end
    else

      if !properties_array.include?(GlobalConstant::User.token_sale_double_optin_mail_sent_property)
        # FOR API USERS and non verify page opted in users
        if properties_array.include?(GlobalConstant::User.token_sale_kyc_submitted_property)
          GlobalConstant::User.get_token_sale_state_page_names("profile_page")
        else
          GlobalConstant::User.get_token_sale_state_page_names("kyc_page")
        end
      else
        if properties_array.include?(GlobalConstant::User.token_sale_kyc_submitted_property)
          GlobalConstant::User.get_token_sale_state_page_names("profile_page")
        elsif properties_array.include?(GlobalConstant::User.token_sale_double_optin_done_property)
          GlobalConstant::User.get_token_sale_state_page_names("kyc_page")
        else
          GlobalConstant::User.get_token_sale_state_page_names("verification_page")
        end
      end

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
  include AttributeParserConcern


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
    begin
      Digest::MD5.hexdigest("#{password}::#{salt}")
    rescue Encoding::CompatibilityError => e
      p = password.to_s.force_encoding("UTF-8")
      s = salt.to_s.force_encoding("UTF-8")
      Digest::MD5.hexdigest("#{p}::#{s}")
    end
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
    key = "#{user_id}:#{current_ts}:#{browser_user_agent}:#{password[-12..-1]}:#{GlobalConstant::SecretEncryptor.cookie_key}"
    sha256_params = {
        string: string_to_sign,
        salt: key
    }
    Sha256.new(sha256_params).perform
  end

  # Get Key Object
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('user.user_details')
  end

  # Get/Set Memcache data for User
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By:
  #
  # @param [Integer] user_id - user id
  #
  # @return [AR] User object
  #
  def self.get_from_memcache(user_id)
    memcache_key_object = User.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: user_id}, memcache_key_object.expiry) do
      User.where(id: user_id).first
    end
  end

  # Bulk Flush Memcache
  #
  # * Author: Aman
  # * Date: 01/11/2017
  # * Reviewed By:
  #
  def self.bulk_flush(user_ids)
    user_ids.each do |uid|
      user_memcache_key = User.get_memcache_key_object.key_template % {id: uid}
      Memcache.delete(user_memcache_key)
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By:
  #
  def memcache_flush
    user_details_memcache_key = User.get_memcache_key_object.key_template % {id: self.id}
    Memcache.delete(user_details_memcache_key)
  end


  # Columns to be removed from the hashed response
  #
  # * Author: Aman
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def self.restricted_fields
    [:user_secret_id, :password]
  end

end