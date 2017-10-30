class Memcache
  class << self

    # get ttl
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [Integer] ttl
    #
    def get_ttl(ttl)
      (ttl.to_i == 0  || ttl > GlobalConstant::Cache.default_ttl) ? GlobalConstant::Cache.default_ttl : ttl.to_i
    end

    # All Config for entity
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key name.
    # @params [Object/String/Integer] value - data need to be stored in memcached
    # @params [Integer] ttl (optional) - memcache key expiry time in seconds
    # @params [Boolean] marshaling (optional) - Marshal data or not?
    #
    def write(key, value, ttl = 0, marshaling = true)
      Rails.cache.write(key, value, {expires_in: get_ttl(ttl), raw: !marshaling})
      nil
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: write: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Read
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key name.
    # @params [Boolean] marshaling (optional) - Marshal data or not?
    #
    # @return [Object/String/Integer] memcached data if present else nil
    #
    def read(key, _marshaling = true)
      Rails.cache.read(key)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: read: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Read Multi
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [Array<String>] keys - memcache keys.
    # @params [Boolean] marshaling (optional) - Marshal data or not?
    #
    # @return [Hash] returns Hash of memcache key to data mapping
    #
    def read_multi(keys, _marshaling = true)
      t_start = Time.now.to_f
      ret = Rails.cache.read_multi(*keys)
      Rails.logger.debug "Memcache multi get took #{Time.now.to_f - t_start} s"
      return ret
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: read_multi: K: #{keys}. M: #{exc.message}, I: #{exc.inspect}" }
      return {}
    end


    # get set memcached
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key.
    # @params [Integer] ttl (optional) - memcache key expiry time in seconds
    # @params [Boolean] marshaling (optional) - Marshal data or not?
    #
    # @return [] if memcache set data is already present, else create and return
    #
    def get_set_memcached(key, ttl = 0, marshaling = true)
      raise 'block not given to get_set_memcached' unless block_given?

      Rails.cache.fetch(key, {expires_in: get_ttl(ttl), raw: !marshaling}) do
        yield
      end

    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: fetch: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # get set memcached multi
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [Array<String>] keys - memcache keys.
    # @params [Integer] ttl (optional) - memcache key expiry time in seconds
    # @params [Boolean] marshaling (optional) - Marshal data or not?
    #
    # @return [] if memcache set data is already present, else create and return
    #
    def get_set_memcached_multi(keys, ttl = 0, marshaling = true)
      raise 'block not given to get_set_memcached' unless block_given?

      Rails.cache.fetch_multi(*keys, {expires_in: get_ttl(ttl), raw: !marshaling}) do
        yield
      end

    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: fetch_multi: K: #{keys.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Exist?
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key.
    # @params [Hash] options (optional)
    #
    # @return [Boolean] if memcache key has some data set
    #
    def exist?(key, options = nil)
      Rails.cache.exist?(key, options)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: exists?: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Delete
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key.
    # @params [Hash] options (optional)
    #
    # @return [Boolean] nil with current behavior, may return true and false if error handling done
    #
    def delete(key, options = nil)
      Rails.cache.delete(key, options)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: delete: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Increment
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key.
    # @params [Integer] inc_value - Incr adds the given positive amount to the counter on the memcached server.
    # @params [Integer] expires_in (optional) - Note that the expires_in will only apply if the counter does not already exist.
    #                                   To increase an existing counter and update its expires_in, use #cas
    # @params [Hash] initial (optional) - If initial is nil, the counter must already exist or the operation will fail and will return nil.
    #                                   Otherwise this method will return the new value for the counter.
    #
    # @return [nil or Integer] if the key does not exits nil is returned. Else increased value is returned.
    #
    def increment(key, inc_value = 1, expires_in = nil, initial = nil)
      puts "Rails.cache.increment(#{key}, #{inc_value}, {expires_in: #{get_ttl(expires_in)}, initial: #{initial}, raw: false})"
      return Rails.cache.increment(key, inc_value, {expires_in: get_ttl(expires_in), initial: initial, raw: false})
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: increment: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      return nil
    end

    # Decrement a cached value. This method uses the memcached decr atomic
    #
    # * Author: Abhay
    # * Date: 30/10/2017
    # * Reviewed By: Kedar
    #
    # @params [String] key - memcache key.
    # @params [Integer] value - Decr subtracts the given positive amount to the counter on the memcached server.
    # @params [Integer] expires_in (optional) - Note that the expires_in will only apply if the counter does not already exist.
    # @params [Hash] initial (optional) - If initial is nil, the counter must already exist or the operation will fail and
    #                                       will return nil. Otherwise this method will return the new value for the counter.
    #
    # @return [nil or Integer] if the key does not exits nil is returned. Else decreased value is returned.
    #
    def decrement(key, value = 1, expires_in = nil, initial = nil)
      puts "Rails.cache.decrement(#{key}, #{value}, {expires_in: #{get_ttl(expires_in)}, initial: #{initial}, raw: false})"
      return Rails.cache.decrement(key, value, {expires_in: get_ttl(expires_in), initial: initial, raw: false})
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: decrement: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      return nil
    end

  end

end
