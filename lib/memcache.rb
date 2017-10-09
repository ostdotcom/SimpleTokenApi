class Memcache
  class << self

    def get_ttl(ttl)
      (ttl.to_i == 0  || ttl > GlobalConstant::Cache.default_ttl) ? GlobalConstant::Cache.default_ttl : ttl.to_i
    end

    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>value</b> <em>(Object/String/Integer)</em> - data need to be stored in memcached
    # * <b>ttl</b> <em>(Integer)</em> - memcache key expiry time in seconds
    # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
    #
    # <b>Returns</b>
    # * <b>nil</b> - a void return - This can be changed if errors are to be caught
    #
    def write(key, value, ttl = 0, marshaling = true)
      Rails.cache.write(key, value, {expires_in: get_ttl(ttl), raw: !marshaling})
      nil
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: write: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>value</b> <em>(Object/String/Integer)</em> - data need to be stored in memcached
    # * <b>time_of_cache</b> <em>(Integer)</em> - memcache key expiry time in seconds
    # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
    #
    # <b>Returns</b>
    # * <b>true</b> - key added
    # * <b>false</b> - error in adding
    #
    def add(key, value, ttl = 0, marshaling = true)
      Rails.cache.write(key, value, {expires_in: get_ttl(ttl), raw: !marshaling, unless_exist: true})
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: add: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      false
    end

    # <b>Expects</b>
    # * params[:key] <em>(String)</em> - memcache key name.
    # * params[:marshaling] <em>(Enum)</em> - Marshal data or not?
    #
    # <b>Returns</b>
    # * memcached data if present else nil
    def read(key, _marshaling = true)
      Rails.cache.read(key)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: read: K: #{key}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # <b>Excepts</b>
    # * params[:keys] <em>(Array)</em> - Array of keys to get
    # * params[:marshaling] <em>(Enum)</em> - Marshal data or not?
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

    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>time_of_cache</b> <em>(Integer)</em> - memcache key expiry time in seconds
    # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
    #
    # <b>Returns</b>
    # * <b>data</b> - if memcache set data is already present, else create and return
    #
    def fetch(key, ttl = 0, marshaling = true)
      if block_given?
        Rails.cache.fetch(key, {expires_in: get_ttl(ttl), raw: !marshaling}) do
          yield
        end
      else
        Rails.cache.read(key)
      end
    rescue Memcached::Error => exc
      Rails.logger.error { "MEMCACHE-ERROR: fetch: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>time_of_cache</b> <em>(Integer)</em> - memcache key expiry time in seconds
    # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
    #
    # <b>Returns</b>
    # * <b>data</b> - if memcache set data is already present, else create and return
    #
    def fetch_multi(keys, ttl = 0, marshaling = true)
      if block_given?
        Rails.cache.fetch_multi(*keys, {expires_in: get_ttl(ttl), raw: !marshaling}) do
          yield
        end
      else
        Rails.cache.read_multi(*keys)
      end
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: fetch_multi: K: #{keys.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # <b>Expects</b>
    # * params[:key] <em>(String)</em> - memcache key name.
    #
    def exist?(key, options = nil)
      Rails.cache.exist?(key, options)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: exists?: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end
    alias :exists? :exist?

    # <b>Expects</b>
    # * params[:key] <em>(String)</em> - memcache key name.
    #
    # <b>Returns</b>
    # * nil with current behavior, may return true and false if error handling required
    def delete(key, options = nil)
      Rails.cache.delete(key, options)
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: delete: K: #{key.inspect}. M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end


    def clear
      Rails.cache.clear
    rescue => exc
      Rails.logger.error { "MEMCACHE-ERROR: clear: M: #{exc.message}, I: #{exc.inspect}" }
      nil
    end

    # Increment a cached value. This method uses the memcached incr atomic
    #
    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>inc_value</b> <em>(Integer)</em> - Incr adds the given positive amount to the counter on the memcached server.
    # * <b>expires_in</b> <em>(Integer)</em> - Note that the expires_in will only apply if the counter does not already exist.
    #                                   To increase an existing counter and update its expires_in, use #cas.
    # * <b>initial</b> <em>(Integer)</em> - If initial is nil, the counter must already exist or the operation will fail and will return nil.
    #                                   Otherwise this method will return the new value for the counter.
    #
    # <b>Returns</b>
    # * <b>nil or integer</b> - if the key does not exits nil is returned. Else increased value is returned.
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
    # <b>Expects</b>
    # * <b>key</b> <em>(String)</em> - memcache key name.
    # * <b>value</b> <em>(Integer)</em> - Decr subtracts the given positive amount to the counter on the memcached server.
    # * <b>expires_in</b> <em>(Integer)</em> - Note that the expires_in will only apply if the counter does not already exist.
    # * <b>initial</b> <em>(Integer)</em> - If initial is nil, the counter must already exist or the operation will fail and
    #                                       will return nil. Otherwise this method will return the new value for the counter.
    #
    # <b>Returns</b>
    # * <b>nil or integer</b> - if the key does not exits nil is returned. Else decreased value is returned.
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
