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

    def self.pepo_campaigns_config
      @pepo_campaigns_config ||= fetch_config.fetch('pepo_campaigns', {}).with_indifferent_access
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

    def self.st_foundation_contracts
      @st_foundation_contracts ||= fetch_config.fetch('st_foundation_contracts', {}).with_indifferent_access
    end

    def self.local_path
      @local_path ||= fetch_config.fetch('local_path', {}).with_indifferent_access
    end

    def self.recaptcha
      @recaptcha ||= fetch_config.fetch('recaptcha', {}).with_indifferent_access
    end

    def self.secret_encryptor
      @secret_encryptor_key ||= fetch_config.fetch('secret_encryptor', {}).with_indifferent_access
    end

    def self.private_ops
      @private_ops ||= fetch_config.fetch('private_ops', {}).with_indifferent_access
    end

    def self.public_ops
      @public_ops ||= fetch_config.fetch('public_ops', {}).with_indifferent_access
    end

    def self.ost_kyc_api
      @ost_kyc_api ||= fetch_config.fetch('ost_kyc_api', {}).with_indifferent_access
    end

    def self.pipedrive
      @pipedrive ||= fetch_config.fetch('pipedrive', {}).with_indifferent_access
    end

    def self.environment_name
      Rails.env
    end

    def self.google_vision
      @vision ||= fetch_config.fetch('google_vision', {}).with_indifferent_access
    end

    def self.kyc_app
      @kyc_app ||= fetch_config.fetch('kyc_app', {}).with_indifferent_access
    end

    def self.kyc_api_base_domain
      @kyc_api_base_domain ||= fetch_config.fetch('kyc_api_base_domain', {}).with_indifferent_access
    end

    def self.estimated_gas_constants
      @estimated_gas_constants ||= fetch_config.fetch('gas_estimation_constants', {}).with_indifferent_access
    end

    def self.aml_config
      @aml_config ||= fetch_config.fetch('aml_config', {}).with_indifferent_access
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