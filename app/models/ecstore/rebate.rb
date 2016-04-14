class Ecstore::Rebate < Ecstore::Base
	self.table_name = "rebates"

	 belongs_to :users, :foreign_key=>"member_id"
	 has_many :card_trading_log

end