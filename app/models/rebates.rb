#encoding:utf-8
class Rebate < ActiveRecord::Base
	self.table_name = "rebates"

  belongs_to :user
end