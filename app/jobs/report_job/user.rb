module ReportJob

  class User < Base

    # Perform
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @param [Hash] params
    #
    def perform(params)
      super
    end

    private

    # Init params
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @param [Hash] params
    #
    def init_params(params)
      super
    end

    # fetch csv_report_job & admin obj
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # Sets @client_kyc_config
    #
    def fetch_details
      super
    end

    # validate
    #
    # * Author: Aman
    # * Date: 18/04/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate
      r = super
      return r unless r.success?

      return error_with_data(
          'rj_u_v_1',
          'Invalid Report type identified',
          'Invalid Report type identified',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @csv_report_job.report_type != GlobalConstant::CsvReportJob.user_report_type

      success
    end

    def get_data_from_db
      offset = 0

      while (true)
        users = user_model_query.limit(MYSQL_BATCH_SIZE).offset(offset).all
        break if users.blank?

        users.each do |user|
          data = get_user_data(user)
          yield(data)
        end

        offset += MYSQL_BATCH_SIZE
      end

      return offset > 0
    end

    def user_model_query
      @user_model_query ||= begin
        ar_relation = ::User.where(client_id: @client_id, status: GlobalConstant::User.active_status)
        ar_relation = ar_relation.sorting_by(@sortings)
        ar_relation = ar_relation.filter_by(@filters)
        ar_relation
      end
    end

    def get_user_data(user)
      {
          id: user.id,
          email: user.email,
          kyc_submitted: user.properties_array.include?(GlobalConstant::User.kyc_submitted_property),
          doptin_mail_sent: user.properties_array.include?(GlobalConstant::User.doptin_mail_sent_property),
          doptin_done: user.properties_array.include?(GlobalConstant::User.doptin_done_property)
      }
    end

    def csv_headers
      ['id', 'email', 'kyc_submitted', 'doptin_mail_sent', 'doptin_done']
    end

  end
end
