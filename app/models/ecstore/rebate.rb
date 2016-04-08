class Ecstore::Rebate < Ecstore::Base
	self.table_name = "rebates"

	 belongs_to :users, :foreign_key=>"member_id"

end