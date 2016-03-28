#encoding:utf-8
class Ecstore::DiscountCode < Ecstore::Base
  self.table_name = "discount_codes"
  self.primary_key = 'code'

  
  self.accessor_all_columns
  belongs_to :user,:foreign_key=>"member_id"

  has_many :users, :foreign_key=>"discount_code"
  has_many :orders, :foreign_key=>"discount_code"
end