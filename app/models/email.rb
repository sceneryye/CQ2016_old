class Email < Base
	self.table_name = "sdb_imodec_emails"
	attr_accessor :addr
end