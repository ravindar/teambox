require 'spec_helper'

describe GoogleDoc do
  it { should belong_to(:user) }
  it { should belong_to(:project) }
  it { should belong_to(:comment) }

  describe "factory" do
    it "should be valid" do
      google_doc = Factory.build(:google_doc)
      google_doc.should be_valid
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

