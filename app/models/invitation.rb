require 'digest/sha1'

class Invitation < RoleRecord
  include Immortal
  belongs_to :invited_user, :class_name => 'User'

  validate :valid_user?
  validate :valid_role?
  validate :user_already_invited?
  validate :email_valid?
  
  attr_reader :user_or_email
  attr_accessor :is_silent, :locale
  attr_accessible :user_or_email, :role, :membership, :invited_user, :locale

  before_create :generate_token
  before_save :copy_user_email, :if => :invited_user
  after_create :auto_accept, :send_email, :update_user_stats

  scope :pending_projects, :conditions => ['project_id IS NOT ?', nil]

  # Reserved so invitations can be sent for other targets, in addition to Project
  def target
    project
  end
  
  def user
    @user ||= user_id ? User.find_with_deleted(user_id) : nil
  end

  def user_or_email=(value)
    self.invited_user = User.find_by_username_or_email(value)
    self.email = value unless self.invited_user
    @user_or_email = value
  end
  
  def accept(current_user)
    if target.is_a? Project
      target.organization.add_member(current_user, membership)
      project.add_user(current_user, {:role => role || 3, :source_user => user})

      # Notify the sender that the invitation has been accepted
      Emailer.send_with_language :accepted_project_invitation, self.user.locale, current_user.id, self.id

    elsif target.is_a? Organization
      target.add_member(current_user, membership)
    end
  end
  
  def editable?(user)
    project.admin?(user) or self.user_id == user.id or self.invited_user_id == user.id
  end
  
  def references
    refs = { :users => [user_id, invited_user_id], :projects => [project_id] }
    refs
  end

  def to_api_hash(options = {})
    base = {
      :id => id,
      :user_id => user_id,
      :invited_user_id => invited_user_id,
      :role => role,
      :project => {
        :permalink => project.permalink,
        :name => project.name
      }
    }
    
    base[:type] = self.class.to_s if options[:emit_type]
    
    base
  end
  
  def to_json(options = {})
    to_api_hash(options).to_json
  end

  def send_email
    return if @is_silent
    if invited_user
      if belongs_to_organization?
        Emailer.send_with_language :project_membership_notification, invited_user.locale, self.id
        self.destroy
      else
        Emailer.send_with_language :project_invitation, invited_user.locale , self.id
      end
    else
      Emailer.send_with_language :signup_invitation, (self.locale || user.locale), self.id
    end
  end
  
  if Rails.env.production? and respond_to? :handle_asynchronously
    handle_asynchronously :send_email 
  end

  protected

  def valid_user?
    @errors.add(:base, 'Must belong to a valid user') if user.nil? or user.deleted?
  end
  
  def valid_role?
    @errors.add(:base, 'Not authorized') if target.is_a?(Project) and user and !target.admin?(user)
  end
  
  def user_already_invited?
    return if invited_user.nil?
    if project and Person.exists?(:project_id => project_id, :user_id => invited_user.id)
      @errors.add :user_or_email, 'is already a member of the project'
    elsif Invitation.exists?(:project_id => project_id, :invited_user_id => invited_user.id)
      @errors.add :user_or_email, 'already has a pending invitation'
    end
  end

  def email_valid?
    return if invited_user
    if valid_email?(email)
      # One final check: do we have an invite for this email?
      if Invitation.exists?(:project_id => project_id, :email => email)
        @errors.add :user_or_email, 'already has a pending invitation'
      end
    else
      @errors.add :user_or_email, 'is not a valid username or email'
    end
  end

  def generate_token
    self.token ||= ActiveSupport::SecureRandom.hex(20)
  end

  def auto_accept
    self.accept(invited_user) if belongs_to_organization?
  end

  def copy_user_email
    self.email ||= invited_user.email
  end

  def belongs_to_organization?
    invited_user and target.respond_to?(:organization) and target.organization.try(:is_user?, invited_user)
  end

  def valid_email?(value)
    EmailValidator.check_address(value)
  end

  def update_user_stats
    user.increment_stat 'invites' if user
  end

end

# == Schema Information
#
# Table name: invitations
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)
#  project_id      :integer(4)
#  role            :integer(4)      default(2)
#  email           :string(255)
#  invited_user_id :integer(4)
#  token           :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  membership      :integer(4)      default(10)
#  deleted         :boolean(1)      default(FALSE), not null
#

