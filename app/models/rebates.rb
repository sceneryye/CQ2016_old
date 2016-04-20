#encoding:utf-8
class Rebate < Base
	self.table_name = "rebates"

  belongs_to :user
end