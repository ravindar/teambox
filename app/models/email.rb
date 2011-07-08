# Used for installations using ar_mailer, which is an alternative to smtp.
# ar_mailer queues emails to be sent in the background, without blocking the UI.

class Email < ActiveRecord::Base

end
# == Schema Information
#
# Table name: emails
#
#  id                :integer(4)      not null, primary key
#  from              :string(255)
#  to                :string(255)
#  last_send_attempt :integer(4)      default(0)
#  mail              :text
#  created_on        :datetime
#

