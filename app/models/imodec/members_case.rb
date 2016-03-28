class Imodec::MembersCase < ActiveRecord::Base
  self.table_name = "members_cases"
 # attr_accessor :name, :description,:parent_id

 # self.accessor_all_columns

  belongs_to :controller,:class_name=>"Ecstore::Member",:foreign_key=>"member_id"

end