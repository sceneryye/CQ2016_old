#encoding:utf-8
class HomeController < ApplicationController
  before_filter :find_user
	# layout 'magazine'
	layout 'application'

	def index

		@title = "昌麒投资"
		#@home = Ecstore::Home.where(:supplier_id=>nil).last
		@goods = Ecstore::Good.where(:marketable=>'true').order("p_order ASC")
		@categories = Ecstore::Category.where("parent_id>0 and disabled='false'")
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
	end

	def index1

		@title = "昌麒投资"
		#@home = Ecstore::Home.where(:supplier_id=>nil).last
		@goods = Ecstore::Good.where(:marketable=>'true').order("p_order ASC")
		@categories = Ecstore::Category.where("parent_id>0 and disabled='false'")
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
	end

	def blank
		@return_url = params[:return_url]
		render :layout=>nil
	end

	def topmenu
		render :layout=>nil
	end
	
	def subscription_success
		@title = "昌麒投资"
	end

end
