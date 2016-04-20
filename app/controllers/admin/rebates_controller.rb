#encoding:utf-8
class Admin::RebatesController < Admin::BaseController
	before_filter :require_permission!


	def show

	end
	  
	def index

	    @rebates =Rebate.paginate(:page=>params[:page],:per_page=>20)
	    @rebates_total = Rebate.count

	end

end
