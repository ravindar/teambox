class Notification < ActiveRecord::Base
  belongs_to :person
  belongs_to :user
  belongs_to :comment
  belongs_to :target, :polymorphic => true
end
# == Schema Information
#
# Table name: notifications
#
#  id          :integer(4)      not null, primary key
#  person_id   :integer(4)
#  user_id     :integer(4)
#  comment_id  :integer(4)
#  target_id   :integer(4)
#  target_type :string(255)
#  sent        :boolean(1)      default(FALSE)
#  read        :boolean(1)      default(FALSE)
#  created_at  :datetime
#  updated_at  :datetime
#

