class Ecstore::MemberAttrValue < Ecstore::Base
	self.table_name = "sdb_dbeav_meta_value_varchar"

	attr_accessor :mr_id, :pk, :value

end