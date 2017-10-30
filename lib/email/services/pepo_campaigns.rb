# Email::Services::PepoCampaigns.new.get_send_info(<pepo_campaign_send_id>)
# Email::Services::PepoCampaigns.new.fetch_users_info([<email_address>])
# Email::Services::PepoCampaigns.new.create_list(<list_name>, <list_description>, 'single')
# Email::Services::PepoCampaigns.new.add_contact(
#   <list_id>,
#   <email_address>,
#   {
#     <attribute_1> => <value>,
#     <attribute_2> => <value>
#   },
#   {
#     <setting_1> => <value>,
#     <setting_2> => <value>,
#   }
#)

module Email

  module Services

    class PepoCampaigns

      require "uri"
      require "open-uri"
      require "openssl"

      attr_accessor :api_key, :api_secret, :version

      # Initialize
      #
      # parameters:
      #   api_key, String
      #   api_secret, String
      #
      def initialize
        @api_key = GlobalConstant::PepoCampaigns.api_key
        @api_secret = GlobalConstant::PepoCampaigns.api_secret
        @api_base_url = GlobalConstant::PepoCampaigns.base_url
        @version = GlobalConstant::PepoCampaigns.version
      end

      # Create a List
      #
      # params:
      #   name, String
      #   source, String
      #   opt_in_type, String
      #
      # returns:
      #   Hash, response data from server
      #
      def create_list(name, source, opt_in_type)
        endpoint = "/api/#{version}/list/create/"
        custom_params = {
            "name" => name,
            "source" => source,
            "opt_in_type" => opt_in_type
        }

        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      # Add Contact to a List
      #
      # params:
      #   list_id, Integer
      #   email, String
      #   attributes, Hash
      #   user_status, Hash
      #
      # returns:
      #   Hash, response data from server
      #
      def add_contact(list_id, email, attributes = {}, user_status = {})
        endpoint = "/api/#{version}/list/#{list_id}/add-contact/"
        custom_params = {
            'email' => email,
            'attributes' => attributes,
            'user_status' => user_status
        }
        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      # Update contact
      #
      # params:
      #   list_id, Integer
      #   email, String
      #   attributes, Hash
      #   user_status, Hash
      #
      # returns:
      #   Hash, response data from server
      #
      def update_contact(list_id, email, attributes = {}, user_status = {})
        endpoint = "/api/#{version}/list/#{list_id}/update-contact/"
        custom_params = {
            "email" => email,
            'attributes' => attributes,
            'user_status' => user_status
        }
        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      # Remove contact
      #
      # params:
      #   list_id, Integer
      #   email, String
      #
      # returns:
      #   Hash, response data from server
      #
      def remove_contact(list_id, email)
        endpoint = "/api/#{version}/list/#{list_id}/remove-contact/"
        custom_params = {
            "email" => email
        }
        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      # Change user status
      #
      # params:
      #   email, String
      #   type, String
      #
      # returns:
      #   Hash, response data from server
      #
      def change_user_status(email, type)
        endpoint = "/api/#{version}/user/change-status/"
        custom_params = {
            'email' => email,
            'type' => type
        }
        base_params = base_params(endpoint,custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      def fetch_users_info(emails)
        endpoint = "/api/#{version}/user/info/"
        custom_params = {
            'emails' => emails.join(',')
        }
        base_params = base_params(endpoint, custom_params)
        raw_url = get_api_url(endpoint) + "?#{base_params.merge(custom_params).to_query}"
        result = URI.parse(raw_url).read
        JSON.parse(result)
      end

      # Send transactional email
      #
      # params:
      #   email, String
      #   template, String
      #   email_vars, Hash
      #
      # returns:
      #   Hash, response data from server
      #
      def send_transactional_email(email, template, email_vars)
        endpoint = "/api/#{version}/send/"
        custom_params = {
            "email" => email,
            "template" => template,
            "email_vars" => email_vars.to_json
        }

        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      def get_send_info(send_id)
        endpoint = "/api/#{version}/get-send/"
        custom_params = {"send_id" => send_id}
        base_params = base_params(endpoint, custom_params)
        raw_url = get_api_url(endpoint) + "?#{base_params.merge(custom_params).to_query}"
        result = URI.parse(raw_url).read
        JSON.parse(result)
      end

      def fetch_custom_attributes
        endpoint = "/api/#{version}/custom-attributes/"
        base_params = base_params(endpoint)
        raw_url = get_api_url(endpoint) +"?#{base_params.to_query}"
        result = URI.parse(raw_url).read
        JSON.parse(result)
      end

      def create_custom_attribute(name, type, options={})
        endpoint = "/api/#{version}/custom-attribute/create/"
        custom_params = {
            "name" => name,
            "type" => type,
            "fallback" => options[:fallback]
        }
        base_params = base_params(endpoint, custom_params)
        uri = post_api_uri(endpoint)
        http = setup_request(uri)
        result = http.post(uri.path, base_params.merge(custom_params).to_query)
        JSON.parse(result.body)
      end

      private

      def setup_request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 5
        http.open_timeout = 5
        if uri.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
        http
      end

      def base_params(endpoint, custom_params={})
        request_time = DateTime.now.to_s
        query_param = custom_params.merge("request-time" => request_time).to_query.gsub(/^&/, '')
        str = "#{endpoint}?#{query_param}"
        signature = generate_signature(api_secret, str)
        {"request-time" => request_time, "signature" => signature, "api-key" => api_key}
      end

      def generate_signature(api_secret, string_to_sign)
        digest = OpenSSL::Digest.new('sha256')
        puts "--------string_to_sign=>#{string_to_sign}-----"
        OpenSSL::HMAC.hexdigest(digest, api_secret, string_to_sign)
      end

      def post_api_uri(endpoint)
        URI(@api_base_url + endpoint)
      end

      def get_api_url(endpoint)
        @api_base_url + endpoint
      end

    end

  end

end