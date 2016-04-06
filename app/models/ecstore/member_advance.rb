class Ecstore::MemberAdvance < Ecstore::Base
	self.table_name = "sdb_b2c_member_advance"
	belongs_to :user,:foreign_key=>"member_id"


	def logged_at
		Time.at(mtime).strftime("%Y-%m-%d %H:%M:%S")
	end
end