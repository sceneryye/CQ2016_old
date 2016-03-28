#encoding:utf-8
class CasesController < ApplicationController
 # before_filter :find_user
	# layout 'magazine'
	layout 'standard'

	def index
		@title = "糖友案例分享-昌麒投资茶"
		@cases = Imodec::MembersCase.all#.order("updated_at DESC")
	end

	def create
		@cases = Imodec::MembersCase.new
		render :layout=>nil
	end

end