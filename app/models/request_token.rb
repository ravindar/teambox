class RequestToken < OauthToken

  attr_accessor :provided_oauth_verifier

  def authorize!(user)
    return false if authorized?
    self.user = user
    self.authorized_at = Time.now
    self.verifier=OAuth::Helper.generate_key(20)[0,20]
    self.save
  end

  def exchange!
    return false unless authorized?
    return false unless verifier==provided_oauth_verifier

    RequestToken.transaction do
      access_token = AccessToken.create(:user => user, :client_application => client_application)
      invalidate!
      access_token
    end
  end

  def to_query
    "#{super}&oauth_callback_confirmed=true"
  end

  def oob?
    self.callback_url=='oob'
  end

end

# == Schema Information
#
# Table name: oauth_tokens
#
#  id                    :integer(4)      not null, primary key
#  user_id               :integer(4)
#  type                  :string(20)
#  client_application_id :integer(4)
#  token                 :string(40)
#  secret                :string(40)
#  callback_url          :string(255)
#  verifier              :string(20)
#  scope                 :string(255)
#  authorized_at         :datetime
#  invalidated_at        :datetime
#  valid_to              :datetime
#  created_at            :datetime
#  updated_at            :datetime
#

