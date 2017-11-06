class GeneralSalt < EstablishSimpleTokenLogDbConnection

  enum salt_type: {
              GlobalConstant::GeneralSalt.user_activity_logging_salt_type => 1
          }, _suffix: true


  # get salt for user activity logging
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By: Sunil
  #
  # Returns[String] Encrypted salt for User activity logging
  #
  def self.get_user_activity_logging_salt_type
    @get_user_activity_logging_salt_type ||= GeneralSalt.user_activity_logging_salt_type.first.salt
  end

end
