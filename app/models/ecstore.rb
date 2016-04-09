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

	end
end