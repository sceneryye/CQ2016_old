class Rebate < ActiveRecord::Base

	 belongs_to :users, :foreign_key=>"member_id"
	 belongs_to :card_trading
	 belongs_to :withdraw

end