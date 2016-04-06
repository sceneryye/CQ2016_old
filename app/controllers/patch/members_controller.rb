#encoding:utf-8
require 'axlsx'

class Patch::MembersController < ApplicationController
	
	before_filter :authorize_user!
	# layout 'standard'
	layout "application"

	before_filter do
		clear_breadcrumbs
		add_breadcrumb("我的昌麒",:member_path)
	end

  def new
    if @user && (@user.member_lv_id>1 || @user.apply_type>1)
      redirect_to advance_member_path
    end
    if params[:apply_type]=='2'
      @checked2='checked'
    else
      @checked3='checked'
    end
  end


  def update
    @user.update_attributes(ecstore_user_params.merge!(:apply_time=>Time.now))
    redirect_to '/card/activation?@notic=卡号不正确或者已经被使用'
   
      
    # if @user.update_attributes(ecstore_user_params.merge!(:apply_time=>Time.now))
    #   redirect_to advance_member_path
    # else
    #   @notic = '卡号不正确或者已经被使用'
   
    #   render "new"
    # end
  end

  def advance
    @deposit = 0
    if @user.member_lv_id<2 #普通会员
        if @user.apply_type>1 #用户已申请
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
		@orders = @user.orders.paginate(:page=>params[:page],:per_page=>10)
		add_breadcrumb("我的订单")
     @coupon_id = params[:coupon_id]
    if @coupon_id
      render :layout=>'coupons'
    end
	end

  def shares
    @orders =Ecstore::Order.where(:discount_code=>@user.discount_code).paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("我的返利")
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

  #post
  def coupon_check
    @discount_code = Ecstore::DiscountCode.where(:status=>'0',
        :code=>params[:discount_code][:code],
        :password=>params[:discount_code][:password])

    if @discount_code.size>0
      @discount_code.first.update_attributes(:member_id=>@user.member_id,:status=>'1')
      Ecstore::UserCoupon.new do |coupon|
        coupon.member_id  = @user.member_id
        coupon.coupon_id  =  @discount_code.first.coupon_id
        coupon.coupon_code =  @discount_code.first.code
      end.save
      Ecstore::Member.find_by_member_id(@user.member_id).update_attributes(:advance=>@user.advance+100,:member_lv_id=>'1')
      redirect_to "/member/coupons?coupon_id=#{@discount_code.first.coupon_id}"#coupons_member_url(:coupon_id=>params[:coupon_id])
    else
      @flash_mesage='卡券号或密码不正确'
    end
   
  #  render coupons
  end


  def goods
    @orders = @user.orders.joins(:order_items).where('sdb_b2c_order_items.storaged is null').paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("我的商品")
  end

  def inventorys
    @inventorys = @user.inventorys.paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("我的库存")
  end

  def inventorylog
    @inventorylog = @user.inventory_log.order("createtime desc").paginate(:page=>params[:page],:per_page=>10)
    add_breadcrumb("出入库记录")
  end

  def export_inventory
    #以后会加入时间区段限制条件
    conditions = { :member_id=>current_account }
    inventorylog = Ecstore::InventoryLog.where(conditions)
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.styles do |s|
      head_cell = s.add_style  :b=>true, :sz => 10, :alignment => { :horizontal => :center,
                                                                    :vertical => :center}
      product_cell =  s.add_style  :sz => 9, :alignment => {:vertical => :top}

      workbook.add_worksheet(:name => 'Product') do |sheet|

        sheet.add_row ['出/入库','产品编号','条形码','图片','商品名称','价格' ,'出入库数量', '出入库时间'] ,:style=>head_cell

        row_count=0

        inventorylog.each do |log|

          in_or_out =log.in_or_out== "\1"  ? '入库' : '出库'
          createtime =Time.at(log.createtime).to_s
      #log.quantity.to_s,log.product_id.quantity.to_s,
          sheet.add_row [in_or_out,log.bn,log.barcode.to_s,nil,log.name,log.price,log.quantity,createtime] ,
                        :style=>product_cell,:height=>50

          row_count +=1

          filename="/home/trade/pics#{log.good.medium_pic}"
          if not FileTest::exist?(filename)
            filename = "#{Rails.root}/app/assets/images/gray_bg.png"
          end
          img = File.expand_path(filename)
          sheet.add_image(:image_src => img, :noSelect => true, :noMove => true) do |image|
            image.width=50
            image.height=80
            image.start_at 3,  row_count
          end

          sheet.column_widths nil, nil,nil,10
        end
      end
    end

    send_data package.to_stream.read,:filename=>"inventory_#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx"
  end
  private
  def ecstore_user_params
    params.require(:ecstore_user).permit(:name,:card_num,:id_card_number,:area,:mobile,:addr,:sex)
  end

	
end
