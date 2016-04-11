#encoding:utf-8
class Store::OrdersController < ApplicationController
  before_filter :authorize_user!
  layout 'application'

  def create

    addr = Ecstore::MemberAddr.find_by_addr_id(params[:member_addr])

     
     @order = Ecstore::Order.new order_params 
    if addr
      ["name","area","addr","zip","tel","mobile"].each do |key,val|
          @order.send("ship_#{key}=" , addr.attributes[key])
      end
    end

   
    return_url=params[:return_url]
    platform=params["platform"];
   
    @order.ip = request.remote_ip
    @order.member_id = @user.member_id

   
    @line_items.each do |line_item|
      product = line_item.product
      good = line_item.good
      
      @order.order_items << Ecstore::OrderItem.new do |order_item|
        order_item.product_id = product.product_id
        order_item.bn = product.bn
        order_item.name = product.name
        
        #会员优惠价格四舍五入
        order_item.price = product.price
        order_item.goods_id = good.goods_id
        order_item.type_id = good.type_id
        order_item.nums = line_item.quantity.to_i
        order_item.item_type = "product"
         if params[:cart_total_final].nil?
         order_item.amount = order_item.price * order_item.nums
         else
           order_item.amount =  params[:cart_total_final]
         end

        product_attr = {}
        # product.spec_desc["spec_value"].each  do |spec_id,spec_value|
        #   spec = Ecstore::Spec.find_by_spec_id(spec_id)
        #   product_attr.merge!(spec_id=>{"label"=>spec.spec_name,"value"=>spec_value})
        # end
        order_item.addon = { :product_attr => product_attr }.serialize

        # @order.total_amount += order_item.calculate_amount
      end
      #     else
      #       debug_line_item +=line_item.id.to_s + '|'
      #    end
    end
    #if debug_line_item
    #  return render :text=>debug_line_item
    #end
    # ==== promotion gifts =====
    gifts = params[:gifts] || []
    gifts.each do |gift_id|
      gift = Ecstore::Product.find_by_product_id(gift_id)
      @order.order_items  << Ecstore::OrderItem.new do |order_item|
        order_item.product_id = gift_id
        order_item.goods_id = gift.goods_id
        order_item.type_id = gift.good.type_id if gift.good
        order_item.bn = gift.bn
        order_item.name = gift.name
        order_item.price = gift.price
        order_item.nums = 1
        order_item.item_type = 'gift'
        order_item.addon = nil
        order_item.amount = 0
      end
    end


    # if @pmtable
      # ==== coupons======
      codes = params[:coupon].present? ? params[:coupon][:codes] : []
      coupons =  codes.collect do |code|
        Ecstore::NewCoupon.check_and_find_by_code(code)
      end.compact

      coupons.each do |coupon|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'coupon'
          order_pmt.pmt_id = coupon.id
          order_pmt.pmt_amount = coupon.pmt_amount(@line_items)
          order_pmt.pmt_name = coupon.name
          order_pmt.pmt_desc = coupon.desc
          order_pmt.coupon_code = coupon.current_code
        end
      end
      # === goods promotions =====
      @goods_promotions = Ecstore::Promotion.matched_goods_promotions(@line_items)
      @goods_promotions.each do |promotion|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'goods'
          order_pmt.pmt_id = promotion.id
          order_pmt.pmt_amount = promotion.goods_pmt_amount(@line_items)
          order_pmt.pmt_name = promotion.name
          order_pmt.pmt_desc = promotion.desc
        end
      end
      # ==== order promotions =====
      @order_promotions = Ecstore::Promotion.matched_promotions(@line_items)
      @order_promotions.each do |promotion|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'order'
          order_pmt.pmt_id = promotion.id
          order_pmt.pmt_amount = promotion.pmt_amount(@line_items)
          order_pmt.pmt_name = promotion.name
          order_pmt.pmt_desc = promotion.desc
        end
      end
    # end

    if @order.save
      @line_items.delete_all

      Ecstore::OrderLog.new do |order_log|
        order_log.rel_id = @order.order_id
        order_log.op_id = @order.member_id
        order_log.op_name = @user.login_name
        order_log.alttime = @order.createtime
        order_log.behavior = 'creates'
        order_log.result = "SUCCESS"
        order_log.log_text = "订单创建成功！"
      end.save
      if return_url.nil?        
          redirect_to order_path(@order)
      else
        redirect_to return_url
      end
    else
      @addrs =  @user.member_addrs
      @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first
      @coupons = @user.usable_coupons
      render :new
    end

  end
  
  def share_order
    supplier_id =params[:supplier_id]
    @supplier = Ecstore::Supplier.find(supplier_id)
    @order =Ecstore::Order.find_by_order_id(params[:id])

    render :layout=>@supplier.layout
  end

  def out_inventory
    return_url =  request.env["HTTP_REFERER"]
    return_url =  member_goods_url if return_url.blank?

    @inventory = Ecstore::Inventory.where(:member_id=>current_account,:product_id=>params[:id]).first

    if @inventory.blank?
    #全部出库，删除记录
    else
      #部分出库，修改数量
      quantity =  @inventory.quantity - @inventory.quantity
      Ecstore::Inventory.where(:member_id=>current_account,:product_id=>params[:id]).update_all(:quantity=>quantity)
    end


    Ecstore::InventoryLog.new do |inventory_log|
      inventory_log.in_or_out =false
      inventory_log.member_id = @inventory.member_id
      inventory_log.goods_id =@inventory.goods_id
      inventory_log.product_id =@inventory.product_id
      inventory_log.price = @inventory.price
      inventory_log.quantity =@inventory.quantity
      inventory_log.name =@inventory.name
      inventory_log.bn = @inventory.bn
      inventory_log.barcode = @inventory.barcode
      inventory_log.createtime = Time.now.to_i
    end.save


    redirect_to return_url
  end

  def to_inventory
    return_url =  request.env["HTTP_REFERER"]
    return_url =  member_goods_url if return_url.blank?

    @order_item =  Ecstore::OrderItem.find(params[:id])

    @new_inventory = Ecstore::Inventory.where(:member_id=>current_account,:product_id=>@order_item.product_id).first

    @inventory =  Ecstore::Inventory.new

    if @new_inventory.blank?
      @inventory.member_id = @order_item.order.member_id
      @inventory.goods_id =@order_item.goods_id
      @inventory.product_id =@order_item.product_id
      @inventory.price = @order_item.price
      @inventory.quantity =@order_item.nums
      @inventory.name =@order_item.name
      @inventory.bn = @order_item.bn
      @inventory.barcode = @order_item.product.barcode
      @inventory.save
    else
      quantity =  @new_inventory.quantity + @order_item.nums
      Ecstore::Inventory.where(:member_id=>current_account,:product_id=>@order_item.product_id).update_all(:quantity=>quantity)
    end


    Ecstore::InventoryLog.new do |inventory_log|
      inventory_log.in_or_out =true
      inventory_log.order_item_id=@order_item.item_id
      inventory_log.order_id = @order_item.order_id
      inventory_log.member_id = @order_item.order.member_id
      inventory_log.goods_id =@order_item.goods_id
      inventory_log.product_id =@order_item.product_id
      inventory_log.price = @order_item.price
      inventory_log.quantity =@order_item.nums
      inventory_log.name =@order_item.name
      inventory_log.bn = @order_item.bn
      inventory_log.barcode = @order_item.product.barcode
      inventory_log.createtime = Time.now.to_i
    end.save


    @order_item.update_attribute :storaged, true
    redirect_to return_url
  end

  def index
    supplier_id = params[:supplier_id]
    if  @user
      supplier_id = @user.account.supplier_id
      if supplier_id == nil
        supplier_id=78
      end
      @supplier = Ecstore::Supplier.find(supplier_id)
      @orders =  @user.orders.order("createtime desc")
    else
      return_url={:return_url => "/goods?platform=#{params["platform"]}&supplier_id=#{supplier_id}"}.to_query
      redirect_to "/auto_login?#{return_url}&id=#{supplier_id}"
    end
  end

  def show

    @order = Ecstore::Order.find_by_order_id(params[:id])
    
  end


  def new
    # @order = Ecstore::Order.new

    @addrs =  @user.member_addrs
    
    @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first

   
  end

  def new_mobile_addr

    supplier_id= @user.account.supplier_id
    if supplier_id==nil
      supplier_id=78
    end
    @supplier = Ecstore::Supplier.find(supplier_id)

    @addrs =  @user.member_addrs
    @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first
    if params[:return_url]
      @return_url=params[:return_url]
     end
    render :layout=>@supplier.layout

  end

  def addr_detail
    @addr = Ecstore::MemberAddr.find(params[:id])
   supplier_id=params[:supplier_id]
    @supplier = Ecstore::Supplier.find(supplier_id)
    @method = :put

    render :layout=>@supplier.layout
  end

 def edit_addr
   @addr = Ecstore::MemberAddr.find(params[:id])
   if @addr.update_attributes(params[:addr])
      respond_to do |format|
       format.js
       format.html { redirect_to "/orders/new_mobile?platform=mobile" }
     end
   else
     render 'error.js' #, status: :unprocessable_entity
   end
 end


  def new_mobile

    supplier_id= @user.account.supplier_id

    if supplier_id.nil?
      supplier_id=78
    end

   sql = "SELECT SUM(price*quantity) AS total,mdk.sdb_b2c_cart_objects.supplier_id,SUM(freight)/count(*) AS freight FROM mdk.sdb_b2c_cart_objects
    INNER JOIN mdk.sdb_b2c_goods ON SUBSTRING_INDEX(SUBSTRING_INDEX(mdk.sdb_b2c_cart_objects.obj_ident,'_',2),'_',-1) = mdk.sdb_b2c_goods.goods_id
    WHERE mdk.sdb_b2c_cart_objects.member_id=#{@user.member_id}
    GROUP BY mdk.sdb_b2c_cart_objects.supplier_id"
    @cart_total_by_supplier = ActiveRecord::Base.connection.execute(sql)
    @cart_freight = 0
    @favorable_terms = 0

    @cart_total_by_supplier.each(:as => :hash) do |row|
      if (row["total"]>=60 && row["supplier_id"]==97) || (row["total"]>=380 &&row["supplier_id"]==77) #|| @cart_total==0.01 #测试商品
        @favorable_terms -=row["freight"]
      end
      @cart_freight += row["freight"]
    end


    @cart_total_final = @cart_total+ @cart_freight + @favorable_terms
    @addrs =  @user.member_addrs
    if @addrs.size==0
      redirect_to "/orders/new_mobile_addr?supplier_id=#{supplier_id}&return_url=%2forders%2fnew_mobile?supplier_id%3d#{supplier_id}"
    else
      @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first

      if @pmtable
        @order_promotions = Ecstore::Promotion.matched_promotions(@line_items)
        @goods_promotions = Ecstore::Promotion.matched_goods_promotions(@line_items)
        @coupons = @user.usable_coupons
      end
      @supplier = Ecstore::Supplier.find(supplier_id)
      render :layout=>@supplier.layout
    end
  end


  def share
    wechat_user = params[:FromUserName]
    if @user
      wechat_user=@user.account.login_name
    end
    @supplier = Ecstore::Supplier.find(params[:supplier_id])
    @share=0
    @sharelast = 0
    if wechat_user
      @order_all = Ecstore::Order.where(:recommend_user=>wechat_user,:pay_status=>'1').select("sum(commission) as share").group(:recommend_user).first

      #return render :text=>@order.final_amount
      if @order_all
        @share = @order_all.share.round(2)
        @order_last =Ecstore::Order.where(:recommend_user=>wechat_user,:pay_status=>'1').order("createtime desc").first
        if @order_last
          @sharelast = @order_last.commission
        end
      end
    end

    render :layout=>@supplier.layout

  end


  def pay
    @order  = Ecstore::Order.find_by_order_id(params[:id])
    if @order &&@order.status == 'active' && @order.pay_status == '0'
      @order.update_attribute :payment, order_params[:payment]
    else
      render :text=>"不存在的订单不能支付!"
    end
  end

  def detail
    @order  = Ecstore::Order.find_by_order_id(params[:id])
  end

  def check_coupon
    codes = params[:codes] || []

    now_code = codes.delete_at(0)
    now_coupon = Ecstore::NewCoupon.check_and_find_by_code(now_code)

    unless now_coupon
      return render :js=>"alert('该优惠券不存在')"
    end

    @coupons = codes.collect do |code|
      Ecstore::NewCoupon.check_and_find_by_code(code)
    end.compact #.sort { |x,y| y.priority <=> x.priority }

    if @coupons.size > 0 && @coupons.include?(now_coupon)
      render :js=>"alert('同一种的优惠券只能使用一次')"
      return
    end

    @coupons << now_coupon if now_coupon

    @coupons.sort! { |x,y| y.priority <=> x.priority }

    @useable = {}
    exclusive = false

    @coupons.each do |coupon|
      if coupon.test_condition(@line_items)
        if !exclusive
          @useable[coupon.current_code] =  true
        else
          @useable[coupon.current_code] =  false
        end

        exclusive = coupon.exclusive
      else
        @useable[coupon.current_code] =  false
      end
    end

    @coupon_amount = @coupons.select do |coupon|
      @useable[coupon.current_code]
    end.collect { |coupon| coupon.pmt_amount(@line_items) }.inject(:+)

  end



  def destroyaddr

    @addr = Ecstore::MemberAddr.find(params[:addr_idsss])            ### 删除地址
    @addr.destroy

  end


  def serach_order
    departure= params[:departure]
    arrival= params[:arrival]
    @un= Ecstore::Express.serachall(departure,arrival)
  end


  def mobile_show_order
    supplier_id=params[:supplier_id]

    @order =Ecstore::Order.find_by_order_id(params[:id])
     @delivery=Ecstore::Delivery.find_by_order_id(params[:id])

    @supplier  =  Ecstore::Supplier.find(supplier_id)
    render :layout=>@supplier.layout


  end

  private
  def order_params
   params.require(:order).permit(:order_id,:ship_day, :ship_special,:from_addr, :ship_time2, 
      :coupon, :coupon_no,:province,:city,:district,:weight,:recommend_user,:member_id,:payment,:ip)

  end

end
