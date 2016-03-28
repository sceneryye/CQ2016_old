class Imodec::Category < ActiveRecord::Base
  attr_accessor :name

  has_many :topics
end
