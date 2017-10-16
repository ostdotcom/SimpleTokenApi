# frozen_string_literal: true
module GlobalConstant

  class Base

    def self.memcache_config
      @memcache_config ||= fetch_config.fetch('memcached', {}).with_indifferent_access
    end

    def self.kms
      @kms ||= fetch_config.fetch('kms', {}).with_indifferent_access
    end

    def self.aws
      @aws ||= fetch_config.fetch('aws', {}).with_indifferent_access
    end

    def self.cynopsis
      @cynopsis ||= fetch_config.fetch('cynopsis', {}).with_indifferent_access
    end

    def self.pepo_campaigns_config
      @pepo_campaigns ||= fetch_config.fetch('pepo_campaigns', {}).with_indifferent_access
    end

    def self.s3
      @s3 ||= fetch_config.fetch('s3', {})
    end

    def self.redis_config
      @redis_config ||= fetch_config.fetch('redis', {})
    end

    def self.st_token_sale
      @st_token_sale ||= fetch_config.fetch('st_token_sale', {}).with_indifferent_access
    end

    def self.local_path
      @local_path ||= fetch_config.fetch('local_path', {}).with_indifferent_access
    end

    def self.recaptcha
      @recaptcha ||= fetch_config.fetch('recaptcha', {}).with_indifferent_access
    end

    private

    def self.fetch_config
      @f_config ||= begin
        template = ERB.new File.new("#{Rails.root}/config/constants.yml").read
        YAML.load(template.result(binding)).fetch('constants', {}) || {}
      end
    end
  end

end