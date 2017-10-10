# frozen_string_literal: true
module GlobalConstant

  class Base

    def self.memcache_config
      @memcache_config ||= fetch_config.fetch('memcached', {})
    end

    def self.kms
      @kms ||= fetch_config.fetch('kms', {})
    end

    def self.aws
      @aws ||= fetch_config.fetch('aws', {})
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