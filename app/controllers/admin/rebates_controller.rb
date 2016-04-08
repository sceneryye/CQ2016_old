#encoding:utf-8
class Admin::RebatesController < Admin::BaseController
	before_filter :require_permission!


	def show

	end
	  
	def index

	    @rebates =Ecstore::Rebate.paginate(:page=>params[:page],:per_page=>20)
	    @rebates_total = Ecstore::Rebate.count

	end

end
