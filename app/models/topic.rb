# == Schema Information
# Schema version: 20090216032013
#
# Table name: topics
#
#  id                :integer(4)      not null, primary key
#  forum_id          :integer(4)      
#  person_id         :integer(4)      
#  name              :string(255)     
#  forum_posts_count :integer(4)      default(0), not null
#  created_at        :datetime        
#  updated_at        :datetime        
#

class Topic < ActiveRecord::Base
  include ActivityLogger
  
  MAX_NAME = 100
  NUM_RECENT = 6
  
  attr_accessible :name
  
  belongs_to :forum, :counter_cache => true
  belongs_to :person
  has_many :posts, :order => 'created_at DESC', :dependent => :destroy,
                   :class_name => "ForumPost"
  has_many :activities, :foreign_key => "item_id", :conditions => "item_type = 'Topic'", :dependent => :destroy
  validates_presence_of :name, :forum, :person
  validates_length_of :name, :maximum => MAX_NAME
  
  after_create :log_activity
  
  def self.find_recent
    find(:all, :order => "created_at DESC", :limit => NUM_RECENT)
  end

  def self.find_recently_active(forum, page = 1)
    topics = forum.topics.delete_if {|t| t.posts.length == 0}
    topics.sort_by {|t| t.posts.first.created_at}.reverse.paginate( :page => page )
  end

  private
  
    def log_activity
      add_activities(:item => self, :person => person)
    end
end
