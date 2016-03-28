#encoding:utf-8
class Store::CartController < ApplicationController
	 before_filter :find_user
	 layout 'application'

  def index

  		@coupon_id = params[:coupon_id]

  		@discount = 1

  		if @coupon_id.nil? ||@coupon_id.empty?
  			@discount = 0.75
  			@shoping_url = '/#pricing'
			#render :layout=>"cart"
		else
			@shoping_url ="/coupon_goods?coupon_id=#{ @coupon_id}"
			#render :layout=>'coupons'
		end
  end

	
	def add
     
	    if signed_in?
			member_id = @user.member_id
			member_ident = Digest::MD5.hexdigest(@user.member_id.to_s)
		else
			member_id = -1
			member_ident = @m_id
		end

		# parse params
		specs = params[:product].delete(:specs)
		customs = params[:product].delete(:customs)
		quantity = params[:product].delete(:quantity).to_i
		goods_id = params[:product][:goods_id]
		@coupon_id = params[:product][:coupon_id]

	    if quantity.blank? || quantity ==0
	       quantity=1
	    end
    
		#return render :text=> "specs:#{specs[0].length},customs:#{customs},quantity:#{quantity},goods_id:#{goods_id}"
		# product_id = specs.collect do |spec_value_id|
		# 	Ecstore::GoodSpec.where(params[:product].merge(:spec_value_id=>spec_value_id)).pluck(:product_id)
		# end.inject(:&).first

		@good = Ecstore::Good.find(goods_id)
		# @product  =  @good.products.select do |p|
		# 	p.spec_desc["spec_value_id"].values.map{ |x| x.to_s }.sort == specs.sort
		# end.first
	    if specs[0].empty?
	      @product = @good.products.first
	    else
	      @product  =  @good.products.select do |p|
	        p.good_specs.pluck(:spec_value_id).map{ |x| x.to_s }.sort == specs.sort
	    end.first

	    end		
	    
		#清除从其他渠道进来存入购物车的商品
		if @coupon_id 
			other_cart = Ecstore::Cart.where("member_id=#{member_id} and coupon_id is null")
			other_cart.delete_all
		end

		@cart = Ecstore::Cart.where(:obj_ident=>"goods_#{goods_id}_#{@product.product_id}",
									  :member_ident=>member_ident).first_or_initialize do |cart|
			cart.obj_type = "goods"
			cart.quantity = quantity
			cart.time = Time.now.to_i
			cart.member_id = member_id
			cart.coupon_id = @coupon_id
      		cart.supplier_id=@good.supplier_id
		end

		if @cart.new_record?
			@cart.save
		else
			Ecstore::Cart.where(:obj_ident=>@cart.obj_ident,:member_ident=>member_ident).update_all(:quantity=>@cart.quantity+quantity)
			@cart.quantity = (@cart.quantity+1)
		end

		# if @product.semi_custom?
		# 	ident = "#{@user.member_id}#{@product.product_id}#{Time.now.to_i}"
		# 	customs.each do |cus_val|
		# 		cus_val.merge!(:product_id=>@product.product_id,
		# 						:member_id=>@user.member_id,
		# 						:name=>Ecstore::SpecItem.find(cus_val["spec_item_id"]).name,
		# 						:ident=>ident)

		# 		Ecstore::CustomValue.create(cus_val)
		# 	end if customs
		# end

		#calculate cart_total and cart_total_quantity
		find_cart!
    
    redirect_to "/cart?coupon_id=#{@coupon_id}"
   
   
	#rescue
		#render :text=>"add failed"
	end

 
	def update
		quantity = params[:quantity]
		@line_items.where(:obj_ident=>params[:id]).update_all(:quantity=>quantity)
		@line_item  = @line_items.where(:obj_ident=>params[:id]).first
		find_cart!
		render "update"
	end

	def destroy
		_type, goods_id, product_id = params[:id].split('_')
		@line_items.where(:obj_ident=>params[:id]).delete_all
		@user.custom_specs.where(:product_id=>product_id).delete_all if signed_in?

		find_cart!
  #  if params[:platform]=='mobile'
  #    return  render :text=>"删除成功"# redirect_to "/cart/mobile"
  #  else
  		render "destroy"
  #  end
	end

	private
	def cart_params
    	params.require(:cart).permit(:obj_ident,:member_ident,:member_id,:obj_type,:params,:quantity,:time)
  	end
end
