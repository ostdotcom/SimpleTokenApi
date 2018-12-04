module UserManagement
  module SendEmail

  class Approve < ServicesBase
    # Initialize
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [String] email (mandatory) - email
    # @param [Hash] template_vars (optional) - @template_vars
    #
    # @return [UserManagement::SendEmail::Approve]
    #

    def initialize(params)
      super

      @client_id = @params[:client_id]
      @email = @params[:email]
      @template_vars = @params[:template_vars]
    end

    # Perform
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      Email::HookCreator::SendTransactionalMail.new(
          client_id: @client_id,
          email: @email,
          template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
          template_vars: @template_vars
      ).perform
      success
    end

    # Validate and sanitize
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
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


    # Validate and sanitize params
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
    def validate_and_sanitize_params
      puts is_nested_hash_or_array?
      error_indentifiers = []
      error_indentifiers << 'invalid_email' unless Util::CommonValidateAndSanitize.is_valid_email?(@email)
      error_indentifiers << 'invalid_template_vars' if is_nested_hash_or_array?

      return error_with_identifier('invalid_api_params',
                            'um_sa_1', # code can be changed
                                   error_indentifiers
      ) if error_indentifiers.any?
      success
    end


    # Check if template_vars is nested object
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
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
      end if @template_vars.present?
      false
    end

    def check_if_hash_or_array(v)
      Util::CommonValidateAndSanitize.is_hash?(v) || Util::CommonValidateAndSanitize.is_array?(v)
    end


    # Create template vars
    #
    # * Author: Mayur
    # * Date: 03/12/2018
    # * Reviewed By:
    #
    def create_template_vars
      @template_vars = @template_vars.present? ? @template_vars.as_json.deep_symbolize_keys.reverse_merge(GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id))
                           : GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id)
    end



  end

  end
  end
