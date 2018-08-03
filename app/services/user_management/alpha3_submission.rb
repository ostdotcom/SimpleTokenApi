module UserManagement

class Alpha3Submission < ServicesBase

  MAX_ATTRIBUTE_CHARACTER_LENGTH = 2000


  # Initialize
  #
  # * Author: Aniket, Tejas
  # * Date: 03/08/2018
  # * Reviewed By:
  #
  # @params [String] email (mandatory) - email
  # @params [String] name_poc (mandatory) - name poc
  # @params [String] team_bio (mandatory) - team bio
  # @params [String] video_url (mandatory) - video url
  # @params [String] url_blog (mandatory) - url blog
  # @params [String] company_name (Optional) - company name
  # @params [Integer] project_url (Optional) - project url
  # @params [Integer] tech_doc (Optional) - tech doc
  # @params [Integer] twitter_handle (Optional) - twitter handle
  #
  # @return [UserManagement::Alpha3Registration]
  #
  def initialize(params)
    super

    @email = @params[:email].to_s.strip
    @name_poc = @params[:name_poc].to_s.strip
    @team_bio = @params[:team_bio].to_s.strip
    @video_url = @params[:video_url].to_s.strip
    @url_blog = @params[:url_blog].to_s.strip
    @company_name = @params[:company_name].to_s.strip
    @project_url = @params[:project_url].to_s.strip
    @tech_doc = @params[:tech_doc].to_s.strip
    @twitter_handle = @params[:twitter_handle].to_s.strip

  end

  # Perform
  #
  # * Author: Aniket, Tejas
  # * Date: 03/08/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def perform
    r = validate_and_sanitize
    return r unless r.success?

    create_email_service_api_call_hook

    success
  end

  private

  # Validate
  #
  # @return [Result::Base]
  #
  def validate_and_sanitize

    r = validate
    return r unless r.success?

    error_data = {}
    error_data[:email] = 'Please enter a valid email address.' unless Util::CommonValidator.is_valid_email?(@email)
    error_data[:name_poc] = 'Name of POC Project is required.' if @name_poc.blank?
    error_data[:team_bio] = 'Team Members bio is required.' if @team_bio.blank?
    error_data[:video_url] = 'Link to final YouTube submission video is required.' if @video_url.blank?
    error_data[:url_blog] = 'Blogpost URL is required.' if @url_blog.blank?

    [GlobalConstant::PepoCampaigns.name_poc_attribute,
     GlobalConstant::PepoCampaigns.team_bio_attribute,
     GlobalConstant::PepoCampaigns.video_url_attribute,
     GlobalConstant::PepoCampaigns.url_blog_attribute,
     GlobalConstant::PepoCampaigns.project_url_attribute,
     GlobalConstant::PepoCampaigns.tech_doc_attribute,
     GlobalConstant::PepoCampaigns.twitter_handle_attribute].each do |attribute|

      error_data[attribute.to_sym] = "#{attribute} length should be less than 2000"  if instance_variable_get("@#{attribute}").length > MAX_ATTRIBUTE_CHARACTER_LENGTH

    end

    #Param company_name is used as organization_name in campaign
    error_data[:company_name] = "company name length should be less than 2000" if @company_name > MAX_ATTRIBUTE_CHARACTER_LENGTH

    return error_with_data(
        'um_cupd_p_1',
        '',
        '',
        GlobalConstant::ErrorAction.default,
        {},
        error_data
    ) if error_data.present?

    success
  end

  # Create Hook to sync data in Email Service
  #
  # * Author: Aniket, Tejas
  # * Date: 03/08/2018
  # * Reviewed By:
  #
  def create_email_service_api_call_hook

    custom_attributes = {
        GlobalConstant::PepoCampaigns.name_poc_attribute => @name_poc,
        GlobalConstant::PepoCampaigns.team_bio_attribute => @team_bio,
        GlobalConstant::PepoCampaigns.video_url_attribute => @video_url,
        GlobalConstant::PepoCampaigns.url_blog_attribute => @url_blog,
        GlobalConstant::PepoCampaigns.organization_name_attribute => @company_name, #duplicate attribute
        GlobalConstant::PepoCampaigns.project_url_attribute => @project_url,
        GlobalConstant::PepoCampaigns.tech_doc_attribute => @tech_doc,
        GlobalConstant::PepoCampaigns.twitter_handle_attribute => @twitter_handle,

    }

    Email::HookCreator::AddContact.new(
        client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
        email: @email,
        custom_attributes: custom_attributes,
        list_id: GlobalConstant::PepoCampaigns.alpha_3_submission_list_id
    ).perform

  end

end

end