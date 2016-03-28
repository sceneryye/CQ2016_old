class Imodec::Page < ActiveRecord::Base
	
  attr_accessor :body, :title, :user_id, :topic_id

  belongs_to :topic
end
