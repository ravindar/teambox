class Oauth2Verifier < OauthToken
  validates_presence_of :user

  def exchange!(params={})
    OauthToken.transaction do
      Oauth2Token.where(:user_id => user_id, :client_application_id => client_application_id).all.each{|r|r.destroy}
      token = Oauth2Token.create! :user=>user,:client_application=>client_application,:scope=>scope
      invalidate!
      destroy
      token
    end
  end

  def code
    token
  end

  def redirect_url
    callback_url
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(20)[0,20]
    self.valid_to = 10.minutes.from_now
    self.authorized_at = Time.now
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

