#encoding:utf-8
class CardTrading < ActiveRecord::Base
  	
  	belongs_to :card
  	has_many :rebates
end