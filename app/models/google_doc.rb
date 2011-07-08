class GoogleDoc < RoleRecord
  include Immortal
  belongs_to :user
  belongs_to :project
  belongs_to :comment, :touch => true
  
  validates_presence_of :title
  validates_presence_of :url
  validates_presence_of :document_type
  
  attr_accessible :title, :document_type, :url, :edit_url, :acl_url
  
  before_create :copy_ownership_from_comment
  
  private
    def copy_ownership_from_comment
      if comment_id
        self.user_id = comment.user_id
        self.project_id = comment.project_id
      end
    end
end

# == Schema Information
#
# Table name: google_docs
#
#  id            :integer(4)      not null, primary key
#  project_id    :integer(4)
#  user_id       :integer(4)
#  comment_id    :integer(4)
#  title         :string(255)
#  document_id   :string(255)
#  document_type :string(255)
#  url           :string(255)
#  edit_url      :string(255)
#  acl_url       :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  deleted       :boolean(1)      default(FALSE), not null
#

