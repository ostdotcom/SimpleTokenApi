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

    attr_accessor :error,
                  :error_message,
                  :error_display_text,
                  :error_display_heading,
                  :error_action,
                  :error_data,
                  :message,
                  :data,
                  :exception,
                  :http_code

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
      @error_display_heading = params[:error_display_heading] if params.key?(:error_display_heading)
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
      define_method(name) { invalid? }
    end

    # Define success method
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    [:success?].each do |name|
      define_method(name) { valid? }
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
        @error_display_heading.present? ||
        @error_action.present? ||
        @exception.present?
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
          error_display_heading: nil
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
          :error_display_heading
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
      hash = self.to_hash

      if (hash[:error] == nil)
        h = {
            success: true
        }.merge(hash)
        h
      else
        {
            success: false,
            err: {
                code: hash[:error],
                msg: hash[:error_message],
                action: hash[:error_action] || GlobalConstant::ErrorAction.default,
                display_text: hash[:error_display_text].to_s,
                display_heading: hash[:error_display_heading].to_s,
                error_data: hash[:error_data] || {}
            },
            data: hash[:data]
        }
      end

    end

  end

end
