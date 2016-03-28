#encoding:utf-8
class Ecstore::RecommendLog < Ecstore::Base
	self.table_name  = 'sdb_imodec_recommend_log'
	self.accessor_all_columns

	has_one :bill, ->{where(bill_type:"refunds")}, :foreign_key=>"bill_id"

  belongs_to :user,:foreign_key=>"member_id"
  belongs_to :good,:foreign_key=>"goods_id"

end