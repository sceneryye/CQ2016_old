module Ecstore
	def self.database_config
		@ecstore ||= YAML.load_file(Rails.root.join("config","ecstore.yml"))[Rails.env]
	end
	
	class Base < ActiveRecord::Base
		self.abstract_class = true
		# self.establish_connection(
		# 	:adapter=>"mysql2",
		# 	:host=>"localhost",
		# 	:username=>"root",
		# 	:password=>"",
		# 	:database=>"mdk2"
		# )
		self.establish_connection(Ecstore.database_config)

		def self.accessor_all_columns
			self.column_names.each do |col|
          			attr_accessor col.to_sym
       		end
		end
	end
end