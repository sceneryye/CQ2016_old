#encoding:utf-8
class Ecstore::CardTradingLog < Ecstore::Base
	self.table_name = "card_trading_logs"
  	
  	belongs_to :card, :foreign_key=>"card_no"
end