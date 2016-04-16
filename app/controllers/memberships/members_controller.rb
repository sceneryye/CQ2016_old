#encoding:utf-8
require 'axlsx'

class Memberships::MembersController < ApplicationController
	
	before_filter :authorize_user!
	# layout 'standard'
	layout "application"

	before_filter do
		clear_breadcrumbs
		add_breadcrumb("我的昌麒",:member_path)
	end

  def new
   
  end


  def update
    user_params = ecstore_user_params
    addr_params = ecstore_user_params
   

    if @user.update_attributes(user_params.merge!(:apply_time=>Time.now))    

      addr_params.merge!(:member_id=>@user.member_id,:def_addr=>1).delete(:id_card_number)  
      @addr = Ecstore::MemberAddr.create(addr_params)

      redirect_to new_card_path
    else
      render "new"
    end
  end

  def advance
    @deposit = 0
    if @user.member_lv_id<2 #普通会员
        if @user.apply_type>1 #会员已申请
            @member_lv = Ecstore::MemberLv.find(@user.apply_type)
            @deposit = @member_lv.deposit
        else          
          redirect_to '/vip'
        end
    else
       @deposit = @user.member_lv.deposit
    end
  

    @advances = @user.member_advances.paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("我的会员卡积分")
  end
  
  def favorites
    @favorites = @user.favorites.includes(:good).paginate(:page=>params[:page],:per_page=>10).order("create_time desc")
    add_breadcrumb("我的收藏")
  end

	def show
		@orders = @user.orders.limit(5)
		@unpay_count = @user.orders.where(:pay_status=>'0',:status=>'active').size
		add_breadcrumb("我的昌麒")
	end

	def orders
		@orders = @user.orders.order('order_id DESC').paginate(:page=>params[:page],:per_page=>10)
		add_breadcrumb("我的订单")
     @coupon_id = params[:coupon_id]
    if @coupon_id
      render :layout=>'coupons'
    end
	end


	def coupons
    @coupon_id = params[:coupon_id]
    if @coupon_id
  		@user_coupons = @user.user_coupons.where(:coupon_id=>@coupon_id).paginate(:page=>params[:page],:per_page=>10)
    else
      return render :text=>'卡券类型不正确'
    end
		add_breadcrumb("我的卡券")
    render :layout=>'coupons'
  end


  private
   def ecstore_user_params
      params.require(:ecstore_user).permit(:name,:card_num,:area,:mobile,:addr,:sex,:id_card_number,:province, :city, :district,)
    end

	
end
