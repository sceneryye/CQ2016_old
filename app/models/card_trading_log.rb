#encoding:utf-8
class CardTradingLog < ActiveRecord::Base
	self.table_name = "card_trading_logs"
  	
  	belongs_to :card
  	belongs_to :rebate
end