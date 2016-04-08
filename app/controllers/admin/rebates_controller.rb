#encoding:utf-8
class Admin::RebatesController < Admin::BaseController
	before_filter :require_permission!


	def show

	end
	  
	def index

	    @rebates =Ecstore::Rebate.all

	end

end
