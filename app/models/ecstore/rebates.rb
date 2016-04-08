#encoding:utf-8
class Ecstore::Rebate < Ecstore::Base
	self.table_name = "rebates"

  belongs_to :user
end