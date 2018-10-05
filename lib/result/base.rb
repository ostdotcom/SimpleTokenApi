# Success Result Usage:
# > s = Result::Base.success(data: {"k1" => "v1"})
# => #<Result::Base:0x007ffbff521d38 @error=nil, @error_message=nil, @message=nil, @data={"k1"=>"v1"}>
# > s.data
# => {"k1"=>"v1"}
# > s.success?
# => true
# > s.to_json
# => {:success=>true, :data=>{"k1"=>"v1"}}
#
# Error Result Usage:
# > er = Result::Base.error({error: 'err_1', error_message: 'msg', error_action: 'do nothing', error_display_text: 'qwerty', data: {k1: 'v1'}})
# => #<Result::Base:0x007fa08a050848 @error="err_1", @error_message="msg", @error_action="do nothing", @error_display_text="qwerty", @message=nil, @http_code=200, @data={:k1=>"v1"}>
# > er.data
# => {"k1"=>"v1"}
# er.success?
# => false
# > er.to_json
# => {:success=>false, :err=>{:code=>"err_1", :msg=>"msg", :action=>"do nothing", :display_text=>"qwerty"}, :data=>{:k1=>"v1"}}
#
# Exception Result Usage:
# > ex = Result::Base.exception(Exception.new("hello"), {error: "er1", error_message: "err_msg", data: {"k1" => "v1"}})
# => #<Result::Base:0x007fbcccbeb140 @error="er1", @error_message="err_msg", @message=nil, @data={"k1"=>"v1"}>
# > ex.data
# => {"k1"=>"v1"}
# > ex.success?
# => false
# > ex.to_json
# => {:success=>false, :err=>{:code=>"er1", :msg=>"err_msg"}}
#
module Result

  class Base
    # error: internal_code 'l_ev_qr_1'
    # error_message:  error message (unused in final response ) 'something went wrong'
    # error_display_text: general error message 'something went wrong'
    # error_action: (unused in new final response)
    # error_data: array of error for params '{param}'
    # http_code:  standard http code '200/400/403/500/'

    attr_accessor :error,
                  :error_message,
                  :error_display_text,
                  :error_action,
                  :error_data,
                  :message,
                  :data,
                  :exception,
                  :http_code,
                  :api_error_code,
                  :params_error_identifiers,
                  :error_extra_info

    # Initialize
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Hash] params (optional) is a Hash
    #
    def initialize(params = {})
      set_error(params)
      set_message(params[:message])
      set_http_code(params[:http_code])
      @data = params[:data] || {}
    end

    # Set Http Code
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Integer] h_c is an Integer http_code
    #
    def set_http_code(h_c)
      @http_code = h_c || GlobalConstant::ErrorCode.ok
    end

    # Set Error
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Hash] params is a Hash
    #
    def set_error(params)
      @error = params[:error] if params.key?(:error)
      @error_message = params[:error_message] if params.key?(:error_message)
      @error_data = params[:error_data] if params.key?(:error_data)
      @error_action = params[:error_action] if params.key?(:error_action)
      @error_display_text = params[:error_display_text] if params.key?(:error_display_text)
      @api_error_code = params[:api_error_code] if params.key?(:api_error_code)
      @params_error_identifiers = params[:params_error_identifiers] if params.key?(:params_error_identifiers)
      @error_extra_info = params[:error_extra_info] if params.key?(:error_extra_info)
    end

    # Set Error extra info
    #
    # * Author: Pankaj
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    # @param [Hash] error_extra_info is an Hash of extra info to send with error
    #
    def set_error_extra_info(error_extra_info)
      @error_extra_info = error_extra_info
    end

    # Set Message
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] msg is a String
    #
    def set_message(msg)
      @message = msg
    end

    # Set Exception
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Exception] e is an Exception
    #
    def set_exception(e)
      @exception = e
    end

    # is valid?
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Boolean] returns True / False
    #
    def valid?
      !invalid?
    end

    # is invalid?
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Boolean] returns True / False
    #
    def invalid?
      errors_present?
    end

    # Define error / failed methods
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    [:error?, :errors?, :failed?].each do |name|
      define_method(name) {invalid?}
    end

    # Define success method
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    [:success?].each do |name|
      define_method(name) {valid?}
    end

    # are errors present?
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Boolean] returns True / False
    #
    def errors_present?
      @error.present? ||
          @error_message.present? ||
          @error_data.present? ||
          @error_display_text.present? ||
          @error_action.present? ||
          @exception.present? ||
          @api_error_code ||
          @params_error_identifiers.present?
    end

    # Exception message
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String]
    #
    def exception_message
      @e_m ||= @exception.present? ? @exception.message : ''
    end

    # Exception backtrace
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String]
    #
    def exception_backtrace
      @e_b ||= @exception.present? ? @exception.backtrace : ''
    end

    # Get instance variables Hash style from object
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    def [](key)
      instance_variable_get("@#{key}")
    end

    # Error
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base] returns object of Result::Base class
    #
    def self.error(params)
      new(params)
    end

    # Success
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base] returns object of Result::Base class
    #
    def self.success(params)
      new(params.merge!(no_error))
    end

    # Exception
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base] returns object of Result::Base class
    #
    def self.exception(e, params = {})
      obj = new(params)
      obj.set_exception(e)
      if params[:notify].present? ? params[:notify] : true
        send_notification_mail(e, params)
      end
      return obj
    end

    # Send Notification Email
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    def self.send_notification_mail(e, params)
      ApplicationMailer.notify(
          body: {exception: {message: e.message, backtrace: e.backtrace, error_data: @error_data}},
          data: params,
          subject: "#{params[:error]} : #{params[:error_message]}"
      ).deliver
    end

    # No Error
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Hash] returns Hash
    #
    def self.no_error
      @n_err ||= {
          error: nil,
          error_message: nil,
          error_data: nil,
          error_action: nil,
          error_display_text: nil,
          api_error_code: nil,
          params_error_identifiers: []
      }
    end

    # Fields
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Array] returns Array object
    #
    def self.fields
      error_fields + [:data, :message]
    end

    # Error Fields
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Array] returns Array object
    #
    def self.error_fields
      [
          :error,
          :error_message,
          :error_data,
          :error_action,
          :error_display_text,
          :error_extra_info
      ]
    end

    # To Hash
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Hash] returns Hash object
    #
    def to_hash
      self.class.fields.each_with_object({}) do |key, hash|
        val = send(key)
        hash[key] = val if val.present?
      end
    end

    # is request for a non found resource
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def is_entity_not_found_action?
      http_code == GlobalConstant::ErrorCode.not_found
    end


    # To JSON
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    def to_json
      response = nil
      if self.to_hash[:error] == nil
        response = {
            success: true,
            http_code: http_code
        }.merge(self.to_hash)
      else
        response = build_error_response
      end
      response
    end

    # Build error response
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def build_error_response
      hash = self.to_hash
      error_response = {
          success: false,
          err: {
              internal_id: hash[:error],
              msg: hash[:error_display_text].to_s
          },
          data: hash[:data],
          http_code: http_code
      }
      err_data = format_error_data
      error_response[:err].merge!(error_data: err_data) if err_data.present?
      error_response[:err].merge!(error_extra_info: hash[:error_extra_info]) if hash[:error_extra_info].present?

      error_config = @api_error_code.present? ? fetch_api_error_config(api_error_code) : {}

      if error_config.present?
        error_response[:err][:code] = error_config["code"]
        error_response[:err][:msg] = error_config["message"]
        error_response[:http_code] = error_config["http_code"].to_i
      end

      error_response
    end

    # Format error data and merge config messages to it.
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def format_error_data
      return nil if error_data.blank? && params_error_identifiers.blank?

      new_error_data = []
      if params_error_identifiers.present?
        params_error_identifiers.each do |ed|
          ec = fetch_api_params_error_config(ed)
          if ec.present?
            new_error_data << {parameter: ec["parameter"], msg: ec["msg"]}
          else
            parameter_key =  ed.match("missing_(.*)")[1]
            new_error_data << {parameter: parameter_key, msg: "#{parameter_key} is missing"} if parameter_key.present?
            ApplicationMailer.notify(
                to: GlobalConstant::Email.default_to,
                body: "Missing params identifier",
                data: {result_base: self.params_error_identifiers},
                subject: "Warning::Missing params identifier. please add the error details"
            ).deliver
          end
        end
      end
      if error_data.present?
        error_data.each do |k, v|
          new_error_data << {parameter: k, msg: v}
        end
      end

      new_error_data
    end

    # Fetch Api error config
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def fetch_api_error_config(error_code)
      @api_errors ||= YAML.load_file(open(Rails.root.to_s + '/config/error_config/api_errors.yml'))
      @api_errors[error_code]
    end

    # Fetch Api params error config
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def fetch_api_params_error_config(error_code)
      @api_params_errors ||= YAML.load_file(open(Rails.root.to_s + '/config/error_config/params_errors.yml'))
      @api_params_errors[error_code]
    end

  end

end
