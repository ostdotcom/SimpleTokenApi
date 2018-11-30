module UserManagement::EmailKycStatus

  class Approve < ServicesBase

    def initialize(params)
      super

      @client_id = @params[:client_id]
      @email = @params[:email]
      @template_vars = @params[:template_vars]
      validate_and_sanitize
    end

    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_and_sanitize_params
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      create_template_vars

      success
    end


    def validate_and_sanitize_params
      error_with_identifier('invalid_api_params',
                            'um_cea_1', # code can be changed
                            ['invalid_params']
      ) if ! Util::CommonValidateAndSanitize.is_valid_email?(@email) or is_nested_hash_or_array?
    end


    def is_nested_hash_or_array?
      @template_vars.each do |key, val|
        if Util::CommonValidateAndSanitize.is_hash?(val)
          val.each do |k, v|
            if check_if_hash_or_array(v)
              return true
            end
          end
        elsif Util::CommonValidateAndSanitize.is_array?(val)
          val.each do |v|
            if check_if_hash_or_array(v)
              return true
            end
          end
        end
      end
      false
    end

    def check_if_hash_or_array(v)
      Util::CommonValidateAndSanitize.is_hash?(v) || Util::CommonValidateAndSanitize.is_array?(v)
    end

    def create_template_vars
      @template_vars = GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id).merge(@template_vars)
    end


    def perform
      Email::HookCreator::SendTransactionalMail.new(
          client_id: @client_id,
          email: @email,
          template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
          template_vars: @template_vars
      ).perform
    end

  end

end
