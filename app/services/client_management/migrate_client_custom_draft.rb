module ClientManagement
  class MigrateClientCustomDraft < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::MigrateClientCustomDraft]
    #
    def initialize(params)
      super
      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @entity_group, @entity_draft_ids = nil, nil
      @client_templates = {}
      @client_drafts_data = {}
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?


      get_client_templates
      create_client_drafts

      create_entity_group
      create_entity_drafts

      create_entity_group_draft
      create_published_entity_group

      success
    end


    private

    # Validate And Sanitize
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @client, @admin
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    def get_client_templates
      @client_templates = ClientTemplate.where(client_id: @client_id).index_by(&:template_type)
    end

    def create_client_drafts
      common_template = @client_templates[GlobalConstant::ClientTemplate.common_template_type].data
      token_sale_blocked_region_template = @client_templates[GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type].data


      company_logo = common_template[:header][:logo][:src]

      if company_logo.strip == 'https://d36lai1ppm9dxu.cloudfront.net/assets/logo/simple-token-dashboard-logo-1x.png'
        company_logo = 'https://d27ixhmpjdysfk.cloudfront.net/c_assets/simple_token/simple-token-dashboard-logo-1x.png'
      end

      company_logo_size_percent = 15
      company_favicon = common_template[:header][:favicon_src] || company_logo

      if Rails.env.staging?
        company_logo = 'https://s3.amazonaws.com/cwa.stagingkyc.com/c_assets/sta/simpletoken/sample_logo.png'
        company_favicon = ''
      end


      background_gradient = []
      background_gradient_style = common_template[:background_gradient_style].scan(/to bottom,\s*([^)]*)/i)[0][0] rescue "#ffffff 0%, #ffffff 20%,"
      background_gradients_arr = background_gradient_style.split(',').map {|x| x.split(/\s+/)}
      background_gradients_arr.map {|x| x.delete("")}
      background_gradients_arr.each do |a|
        val = a[1]
        val = val.gsub("%", '')
        val = 20 if val.match(/px/)
        background_gradient << {color: rgb_color(a[0]), gradient: val.to_i}
      end
      background_gradient = background_gradient[0..2]

      primary_button_style = common_template[:primary_button_style].scan(/btn-primary *({[a-z0-9#-:;\s]*})/i)[0][0]

      primary_button_border_color = primary_button_style.scan(/border-color:\s*([^;]*)/i)[0][0]
      primary_button_background_color = primary_button_style.scan(/background(-color)?:\s*([^;]*)/i)[0][1]
      primary_button_text_color = primary_button_style.scan(/[{;\s]+color:\s*([^;]*)/i)[0][0]

      primary_button_style_active = common_template[:primary_button_style].scan(/.btn-primary:active[^{]* *({[a-z0-9#-:;\s!]*})/i)[0][0] rescue common_template[:primary_button_style].scan(/.client-primary-btn:active[^{]* *({[a-z0-9#-:;\s!]*})/i)[0][0]
      primary_button_border_color_active = primary_button_style_active.scan(/border-color:\s*([^;]*)/i)[0][0]
      primary_button_background_color_active = primary_button_style_active.scan(/background(-color)?:\s*([^;]*)/i)[0][1]
      primary_button_text_color_active = primary_button_style_active.scan(/[{;\s]+color:\s*([^;]*)/i)[0][0]

      primary_button_border_color_active.gsub!(/!important/i, '')
      primary_button_background_color_active.gsub!(/!important/i, '')
      primary_button_text_color_active.gsub!(/!important/i, '')

      secondary_button_style = common_template[:secondary_button_style].scan(/btn-secondary *({[a-z0-9#-:;\s]*})/i)[0][0]

      secondary_button_border_color = secondary_button_style.scan(/border-color:\s*([^;]*)/i)[0][0]
      secondary_button_text_color = secondary_button_style.scan(/[{;\s]+color:\s*([^;]*)/i)[0][0]
      secondary_button_background_color = secondary_button_style.scan(/background(-color)?:\s*([^;]*)/i)[0][1] rescue 'ffffff'

      secondary_button_style_active = common_template[:secondary_button_style].scan(/.btn-secondary:active[^{]* *({[a-z0-9#-:;\s!]*})/i)[0][0]

      secondary_button_border_color_active = secondary_button_style_active.scan(/border-color:\s*([^;]*)/i)[0][0]
      secondary_button_background_color_active = secondary_button_style_active.scan(/background(-color)?:\s*([^;]*)/i)[0][1]
      secondary_button_text_color_active = secondary_button_style_active.scan(/[{;\s]+color:\s*([^;]*)/i)[0][0]

      secondary_button_border_color_active.gsub!(/!important/i, '')
      secondary_button_background_color_active.gsub!(/!important/i, '')
      secondary_button_text_color_active.gsub!(/!important/i, '')


      terms_condition_link = token_sale_blocked_region_template[:primary_button_href]
      gtm_pixel_id = common_template[:gtm_pixel][:id] rescue ''
      fb_pixel_id = common_template[:fb_pixel][:id] rescue ''
      fb_pixel_version = common_template[:fb_pixel][:version] rescue ''


      footer_html = common_template[:footer_html]

      footer_style = footer_html.scan(/footer style="([^"]*)"/)[0][0]
      footer_html_style = footer_html.scan(/a\s+href=.*style="([^"]*)"/)[0][0]

      footer_text_color = footer_style.scan(/[^-]*color:\s*([^;]*)/i)[0][0]
      footer_background_color = footer_style.scan(/background:\s*([^;]*)/i)[0][0]
      footer_link_color = footer_html_style.scan(/[^-]*color:\s*([^;]*)/i)[0][0]

      footer_text = sanitize_html(footer_html)

      common_draft_data = {
          company_logo: company_logo.to_s.strip,
          company_logo_size_percent: company_logo_size_percent,
          company_favicon: company_favicon,
          background_gradient: background_gradient,

          primary_button_text_color: rgb_color(primary_button_text_color),
          primary_button_background_color: rgb_color(primary_button_background_color),
          primary_button_border_color: rgb_color(primary_button_border_color),
          primary_button_text_color_active: rgb_color(primary_button_text_color_active),
          primary_button_background_color_active: rgb_color(primary_button_background_color_active),
          primary_button_border_color_active: rgb_color(primary_button_border_color_active),

          secondary_button_text_color: rgb_color(secondary_button_text_color),
          secondary_button_background_color: rgb_color(secondary_button_background_color),
          secondary_button_border_color: rgb_color(secondary_button_border_color),
          secondary_button_text_color_active: rgb_color(secondary_button_text_color_active),
          secondary_button_background_color_active: rgb_color(secondary_button_background_color_active),
          secondary_button_border_color_active: rgb_color(secondary_button_border_color_active),

          footer_text_color: rgb_color(footer_text_color),
          footer_link_color: rgb_color(footer_link_color),
          footer_background_color: rgb_color(footer_background_color),
          footer_text: footer_text.to_s.strip,

          terms_condition_link: terms_condition_link.to_s.strip,
          gtm_pixel_id: gtm_pixel_id,
          fb_pixel_id: fb_pixel_id,
          fb_pixel_version: fb_pixel_version
      }

      @client_drafts_data[GlobalConstant::EntityGroupDraft.theme_entity_type] = common_draft_data

      ##############################################################################################################################

      signup_template = @client_templates[GlobalConstant::ClientTemplate.sign_up_template_type].data

      checkbox_html = signup_template[:checkbox_html]
      policy_texts = [sanitize_html(checkbox_html)]


      signup_draft_data = {
          policy_texts: policy_texts
      }
      @client_drafts_data[GlobalConstant::EntityGroupDraft.registration_entity_type] = signup_draft_data

      ###################################################################################################################################################

      kyc_template = @client_templates[GlobalConstant::ClientTemplate.kyc_template_type].data

      kyc_form_title = 'Update Your Registration Details'
      kyc_form_subtitle = 'You will need to supply the following information to complete your registration'

      eth_address_instruction_text = sanitize_html(kyc_template[:ethereum_address_info_html])
      document_id_instruction_text = sanitize_html(kyc_template[:document_info_html])
      kyc_form_popup_checkboxes = kyc_template[:verify_modal][:add_kyc_checkbox_points_html].map {|x| sanitize_html(x)}

      kyc_draft_data = {
          kyc_form_title: kyc_form_title,
          kyc_form_subtitle: kyc_form_subtitle,
          eth_address_instruction_text: eth_address_instruction_text,
          document_id_instruction_text: document_id_instruction_text,
          kyc_form_popup_checkboxes: kyc_form_popup_checkboxes
      }

      @client_drafts_data[GlobalConstant::EntityGroupDraft.kyc_entity_type] = kyc_draft_data

      ###################################################################################################################################################

      dashboard_template = @client_templates[GlobalConstant::ClientTemplate.dashboard_template_type].data

      dashboard_title_text_color = dashboard_template[:timer_element_color]

      timer_element_gradient_style = dashboard_template[:timer_element_gradient_style]

      sale_timer_text_color = timer_element_gradient_style.scan(/color:\s*([^;]*)/i)[0][0]

      sale_timer_background_gradient = []
      sale_timer_gradient_style = timer_element_gradient_style.scan(/to bottom,\s*([^)]*)/i)[0][0]
      sale_timer_gradient_arr = sale_timer_gradient_style.split(',').map {|x| x.split(/\s+/)}
      sale_timer_gradient_arr.map {|x| x.delete("")}

      sale_timer_gradient_arr.each do |ele|
        sale_timer_background_gradient << {color: rgb_color(ele[0]), gradient: ele[1].to_i}
      end

      # sale_timer_background_gradient << {color: rgb_color(sale_timer_gradient_arr[0][0]),gradient: 0}
      # sale_timer_background_gradient << {color: rgb_color(sale_timer_gradient_arr[0][0]),gradient: 50}
      # sale_timer_background_gradient << {color: rgb_color(sale_timer_gradient_arr[-1][0]),gradient: 51}
      # sale_timer_background_gradient << {color: rgb_color(sale_timer_gradient_arr[-1][0]),gradient: 100}

      ethereum_deposit_popup_checkboxes = dashboard_template[:ethereum_confirm_checkbox_points_html].map {|x| sanitize_html(x)}

      middle_banner_text = dashboard_template[:ethereum_deposit_text_html].to_s
      middle_banner_text = middle_banner_text.present? ? middle_banner_text : 'DO NOT use Coinbase, Kraken or any other exchange to purchase Tokens'

      middle_banner_href_style = middle_banner_text.scan(/a\s+href=.*style="([^"]*)"/im)[0][0] rescue nil
      dashboard_middle_banner_link_color = middle_banner_href_style.scan(/[^-]*color:\s*([^;]*)/im)[0][0] rescue 'feb202'

      first_line_last_index = middle_banner_text.index("<").to_i
      dashboard_middle_banner_title_text = middle_banner_text[0..first_line_last_index - 1]

      dashboard_middle_banner_body_text = middle_banner_text[first_line_last_index..-1]
      dashboard_middle_banner_body_text = sanitize_html(dashboard_middle_banner_body_text)
      dashboard_middle_banner_body_text.gsub!("<small>", '')
      dashboard_middle_banner_body_text.gsub!("</small>", '')
      dashboard_middle_banner_body_text.gsub!(/^<br\/?>/, '')
      dashboard_middle_banner_body_text.gsub!(/<\/div>/, '')
      dashboard_middle_banner_body_text.gsub!(/<div[^>]*>/, '')

      telegram_link = dashboard_template[:telegram_href]
      dashboard_bottom_banner_background = dashboard_template[:container_background_color]
      dashboard_middle_banner_text_color = 'ffffff'
      dashboard_bottom_banner_text_color = 'ffffff'
      telegram_button_theme = 'light'
      dashboard_middle_banner_background = dashboard_bottom_banner_background


      dashboard_draft_data = {

          dashboard_title_text_color: rgb_color(dashboard_title_text_color),
          sale_timer_text_color: rgb_color(sale_timer_text_color),
          sale_timer_background_gradient: sale_timer_background_gradient,
          dashboard_middle_banner_link_color: rgb_color(dashboard_middle_banner_link_color),
          dashboard_middle_banner_text_color: rgb_color(dashboard_middle_banner_text_color),
          dashboard_middle_banner_background: rgb_color(dashboard_middle_banner_background),
          dashboard_middle_banner_title_text: dashboard_middle_banner_title_text.to_s.strip,
          dashboard_middle_banner_body_text: dashboard_middle_banner_body_text.to_s.strip,
          dashboard_bottom_banner_text_color: rgb_color(dashboard_bottom_banner_text_color),
          dashboard_bottom_banner_background: rgb_color(dashboard_bottom_banner_background),
          telegram_button_theme: telegram_button_theme,
          telegram_link: telegram_link,
          ethereum_deposit_popup_checkboxes: ethereum_deposit_popup_checkboxes
      }
      @client_drafts_data[GlobalConstant::EntityGroupDraft.dashboard_entity_type] = dashboard_draft_data

###################################################################################################################################################


    end

    # create an entry in entity group
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @entity_group
    #
    def create_entity_group
      @entity_group = EntityGroup.create!(client_id: @client_id,
                                          uuid: Time.now.to_f,
                                          creator_admin_id: @admin_id,
                                          status: GlobalConstant::EntityGroup.active_status,
                                          activated_at: Time.now.to_i)
    end

    # create an entry in entity group
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    # Sets @entity_draft_ids
    #
    def create_entity_drafts
      @entity_draft_ids = {}

      EntityGroupDraft.entity_types.each do |entity_type, _|
        entity_data = @client_drafts_data[entity_type] || {}
        obj = EntityDraft.create!(client_id: @client_id,
                                  last_updated_admin_id: @admin_id,
                                  data: entity_data,
                                  status: GlobalConstant::EntityDraft.active_status)
        @entity_draft_ids[entity_type] = obj.id
      end
    end

    # create all entity group draft
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    #
    def create_entity_group_draft
      @entity_draft_ids.each do |entity_type, draft_id|
        EntityGroupDraft.create!(entity_group_id: @entity_group.id,
                                 entity_type: entity_type,
                                 entity_draft_id: draft_id)
      end

    end

    # create all entity group draft
    #
    # * Author: Aman
    # * Date: 13/08/2018
    # * Reviewed By:
    #
    #
    def create_published_entity_group
      PublishedEntityGroup.create!(client_id: @client_id, entity_group_id: @entity_group.id)
    end

    def rgb_color(hex_color)
      arr = []
      hex_color = hex_color.gsub("#", '')

      if hex_color.length == 6
        arr << hex_color[0..1]
        arr << hex_color[2..3]
        arr << hex_color[4..5]
      elsif hex_color.length == 3
        arr << "#{hex_color[0]}#{hex_color[0]}"
        arr << "#{hex_color[1]}#{hex_color[1]}"
        arr << "#{hex_color[2]}#{hex_color[2]}"
      else
        fail "Invalid color code -#{hex_color}"
      end

      rbg_str = "rgb("
      rbg_str += arr.map {|x| x.to_i(16)}.join(',')
      rbg_str += ')'
      rbg_str.to_s.strip
    end

    def sanitize_html(text)
      # will work only  for footer
      footer_sub_text = text.gsub(/<\s*footer\s+style=[^>]*>/i, '')

      footer_sub_text1 = footer_sub_text.gsub(/style="([^"]*)"/, '')
      footer_sub_text2 = footer_sub_text1.gsub(/title="([^"]*)"/, '')
      footer_sub_text3 = footer_sub_text2.gsub(/class="([^"]*)"/, '')

      footer_sub_text = footer_sub_text3.gsub(/<\/footer>/i, '')
      footer_sub_text.to_s.strip
    end

  end
end

