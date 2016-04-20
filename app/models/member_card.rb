#encoding:utf-8
class MemberCard < ActiveRecord::Base
	self.table_name = "member_cards"

	belongs_to :card, :foreign_key=>"card_id"
	belongs_to :buyer, :foreign_key=>"buyer_id",:class_name=>"User"
	belongs_to :user, :foreign_key=>"user_id",:class_name=>"User"
	belongs_to :user, :foreign_key=>"member_id"

	# validates :user_tel,
	# 		   :presence=>{:presence=>true,:message=>"请填写手机号码"},
	# 		   :if=>Proc.new{ |c| c.card.card_type == 'A' }

	# validates :user_tel,
	# 		   :format=>{:with=>/^\d{11}$/, :multiline => true,:message=>"使用者手机号码必须是11位数字"},
	# 		   :if=>Proc.new{ |c| c.card.card_type == 'A' }

	# validates :buyer_tel,:presence=>{:presence=>true,:message=>"请填写手机号码"}
	# validates :buyer_tel,:format=>{:with=>/^\d{11}$/, :multiline => true,:message=>"购买者手机号码必须是11位数字"}
	
	after_save :sell_card!

	def sell_card!
		self.card.update_attribute :sale_status, true if self.card
	end
end