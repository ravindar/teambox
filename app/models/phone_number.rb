class PhoneNumber < ActiveRecord::Base
  belongs_to :card

  TYPES = ['Work','Mobile','Fax','Home','Skype','Other']
  
  def get_type
    TYPES[account_type]
  end
  
end  
# == Schema Information
#
# Table name: phone_numbers
#
#  id           :integer(4)      not null, primary key
#  card_id      :integer(4)
#  name         :string(255)
#  account_type :integer(4)      default(0)
#

