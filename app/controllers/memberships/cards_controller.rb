#encoding:utf-8
require 'sms'
require 'allinpay'
class Memberships::CardsController < ApplicationController
	# skip_before_filter :authorize_user!
	before_filter :find_user
	layout 'application'

  	include Allinpay

  	def new () end

  	def create
  		
		@card = Ecstore::Card.find_by_no(card_params[:card_num])
		if @card && @card.can_use? && !@card.used?
  			card_id = card_params[:card_num]
			password = card_params[:card_pwd]

			card_info = card_info('会员卡激活', password, card_id)

	        if card_info[:error]
	        	return render text:card_info[:error]
	        else				
	        	@user.update_attribute :card_num ,card_id
				@user.update_attribute :card_validate,'true'
				@card.update_attribute :use_status,true
				@card.update_attribute :used_at,Time.now
				
				if @card.member_card.nil?
					@member_card = Ecstore::MemberCard.new do |member_card|
						member_card.user_id = @user.member_id
						member_card.member_id = @user.member_id
						member_card.card_id = @card.id
					end
					@member_card.save!
				else
					@card.member_card.update_attribute :user_id,@user.member_id
					@card.member_card.update_attribute :member_id,@user.member_id
					member_card.card_id = @card.id
				end

				#发微信通知
				send_message('激活')

				Ecstore::CardLog.create(:member_id=>@user.member_id,
	                                                :card_id=>@card.id,
	                                                :message=>"会员卡激活,用户本人操作")
				redirect_to bank_cards_path

			end
		else
			return render text: '会员卡无法激活'
		end
	end

	def member_card
		@member_card = @user.member_card
	    if @member_card.update_attributes(member_card_params)
	    	redirect_to card_path(0), notice: '会员卡激活成功'
	    else
	    	flash[:error] = "银行卡验证失败" 
	    	render 'bank'
	    end

	end

  	def login

	    password = params[:card][:password]
	    from = params[:from]

	    card_info = card_info(from,password)

		if card_info["error"]
			return render text: card_info
		else
			redirect_to card_path(0)
		end
  	end

  	def show
  		if session[:card_pwd] && params[:id]=='2'
  			card_info '查询余额'
  		end
  		
  		@card_info = Ecstore::MemberAdvance.where(member_id: @user.member_id).last
	end

  	def recharge () end

  	def topup
  		order_id = get_order_id
  		card_id = @user.card_num;
    	prdt_no = "0001";
    	amount =  params[:card][:amount].to_i*100;
    	top_up_way = '1';
    	opr_id = '0229000040';
	    #data = params.permit(:order_id, :card_id, :prdt_no, :amount, :top_up_way, :opr_id, :desn)
	    
	    desn = params[:desn]
	    res_data = ActiveSupport::JSON.decode topup_single_card(order_id, card_id, prdt_no, amount, top_up_way, opr_id, desn)

	    res_info = save_log res_data

	    if res_info[:error]
	    	return render text: res_info[:error]
	    else
	    	card_info = card_info('充值')
	    	redirect_to card_path(1), notice: "成功充值：#{amount/100}"
	    end
	end

  	def edit () end

  	def update
	    card_id = @user.card_num
	    old_pwd = params[:card][:old_pwd]
	    new_pwd = params[:card][:new_pwd]

	    card_info = card_info('修改密码',old_pwd)

	    if card_info[:error]
			return render text: '原密码不正确'
		else
			# reset_password
		    order_id = get_order_id
		    res_data = ActiveSupport::JSON.decode card_reset_password(order_id, card_id, new_pwd)
		    Rails.logger.info res_data
		    card_info = card_info('修改密码',old_pwd)
		   	redirect_to member_path, notice: '密码修改成功'
		end	
	end

	def index
		#@tradings = Ecstore::CardTradingLog.paginate(:page=>params[:page],:per_page=>20)

	    if  @user
	      @tradings =  @user.orders.where(pay_status:'1').order("createtime desc")
	    else
	      redirect_to "/auto_login?#{return_url}&id=1"
	    end
	end

	def rebates
		#@tradings = Ecstore::CardTradingLog.paginate(:page=>params[:page],:per_page=>20)

	    if @user
	    	if params[:status] == '0'
		      @rebates =  @user.orders.where(pay_status:'1').order("createtime desc")
		  end
	    else
	      redirect_to "/auto_login?#{return_url}&id=1"
	    end
	end

  	def renew_record

  		begin_date = params[:begin_date] 
	    end_date = params[:end_date]
	    card_id = params[:card_id]
	    password = params[:password]
	    page_no = params[:page_no]
	    page_size = params[:page_size]
	    return render json: {data: {error_message: '不能查询90天之前的记录！'}} if Time.parse(begin_date) < (Time.now - 3600 * 24 * 90)
	    res_data = ActiveSupport::JSON.decode card_get_trade_log(begin_date, end_date, card_id, password, page_no, page_size)
	    Rails.logger.info res_data
	    render json: {data: res_data}
  	end	

	def pay_with_pwd

	    order_id = get_order_id
	    mer_order_id = order_id
  		card_id = @user.card_num;
	    payment_id = params[:payment_id]
	    amount = params[:amount].to_i*100
	    password = params[:password]
	    res_data = ActiveSupport::JSON.decode pay_with_password(order_id,  mer_order_id, payment_id, amount, card_id, password)
	    Rails.logger.info res_data
	    render json: {data: res_data}
	end	

	def pay_to_client
	    data = params[:pay_to_client]
	    res_data = Hash.from_xml pay_for_another data
	    render json: {data: res_data}
	end
	


	private
	def card_params
	    params.require(:card).permit(:card_num,:card_pwd)
	end

	def member_card_params
	    params.require(:member_card).permit(:bank_name,:bank_card_no,:bank_branch)
	end

	def card_info (from='',password=session[:card_pwd],card_id=@user.card_num )

		if password.blank?
			return {error:'login'}
		end
		@cards_log ||= Logger.new('log/cards.log')

	  	res_data = ActiveSupport::JSON.decode card_get_info(card_id, password)

	    @cards_log.info("[#{@user.login_name}][#{Time.now}]#{res_data}")

	    @card_log = Ecstore::CardLog.create(:member_id=>@user.member_id,
										:card_no=>card_id,
										:message=>"#{res_data.to_json}")

	    if res_data["error_response"]
	 		@cards_log.info("[#{@user.login_name}][#{Time.now}]查询会员卡信息失败")	  
	 		return {error:res_data["error_response"]["sub_msg"]} 	
			###########e.data.ppcs_cardsingleactive_add_response# e.data.error_response.sub_msg					
		else
			
			#{"data":{"card_cardinfo_get_response":{"res_timestamp":20160406213434,"res_sign":"77AFA3C325F8E63404A573B3C306E468","card_info":{"card_stat":0,"brh_id":"0229000040","brand_id":"0001","validity_date":20170210,"card_id":8668083660000001017,"card_product_info_arrays":{"card_product_info":[{"product_stat":0,"product_id":"0001","product_name":"通用金额","validity_date":20170210,"valid_balance":476631,"card_id":8668083660000001017,"account_balance":486631},{"product_stat":0,"product_id":"0282","product_name":"200元现金券","validity_date":20991231,"valid_balance":553619,"card_id":8668083660000001017,"account_balance":553619},{"product_stat":0,"product_id":1000,"product_name":"积分","validity_date":20160210,"valid_balance":1745700,"card_id":8668083660000001017,"account_balance":1745700}]}}}}}
     		
	        status = case res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["product_stat"]
	          		when 0
	          			 '正常'
	          		when 1
	          			'挂失'          
	          		when 2
	          			'冻结'          
	          		when 3
	         			'作废'          
	          		else 
	          			'未知'          
	        end
	         #   message = '卡号：' + card_id + ';  认证日期：' + e.data.card_cardinfo_get_response.card_info.validity_date +';  余额：' + parseFloat(msg.account_balance / 100) + '元' + ';  产品名称：' + msg.product_name + ';  可用余额：' + parseFloat(msg.valid_balance / 100) + '元' + ';  产品有效期：' + msg.validity_date + ';  产品状态：' + state;
	        balance = res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["valid_balance"]
	        balance = (balance.to_f)/100
			
			Ecstore::MemberAdvance.create(:member_id=>@user.member_id,
										  :money=>balance,
										  :message=>"#{from},卡号:#{card_id}",
										  :mtime=>Time.now.to_i,
										  :memo=>"用户本人操作",
										  :import_money=>balance,
										  :explode_money=>0,
										  :member_advance=>balance,
										  :shop_advance=>balance,
										  :disabled=>'false')
			@user.update_attribute :advance, balance

	        session[:card_pwd] = password

	    end
	    return {status: status, balance: balance}
	end

	def get_order_id
	  	order_id = "999990053990001_#{Time.now.to_i}#{rand(100).to_s}"
	end

	def save_log (res_data)
		from =''
		card_no = @user.card_num
		card_id = Ecstore::Card.find_by_no(card_no)[:id]
		member_id = @user.member_id
		@cards_log ||= Logger.new('log/cards.log')

	    @cards_log.info("[#{@user.login_name}][#{Time.now}]#{res_data}")

	    @card_log = Ecstore::CardLog.create(:member_id=>@user.member_id,
										:card_no=>card_no,
										:card_id=>card_id,
										:message=>"#{res_data.to_json}")

	    if res_data["error_response"]
	 		@cards_log.info("[#{@user.login_name}][#{Time.now}]操作失败")	  
	 		return  {error:res_data["error_response"]["sub_msg"]} 	
			###########e.data.ppcs_cardsingleactive_add_response# e.data.error_response.sub_msg					
		else
			
			# #{"card_cardinfo_get_response":{"res_timestamp":20160406213434,"res_sign":"77AFA3C325F8E63404A573B3C306E468","card_info":{"card_stat":0,"brh_id":"0229000040","brand_id":"0001","validity_date":20170210,"card_id":8668083660000001017,"card_product_info_arrays":{"card_product_info":[{"product_stat":0,"product_id":"0001","product_name":"通用金额","validity_date":20170210,"valid_balance":476631,"card_id":8668083660000001017,"account_balance":486631},{"product_stat":0,"product_id":"0282","product_name":"200元现金券","validity_date":20991231,"valid_balance":553619,"card_id":8668083660000001017,"account_balance":553619},{"product_stat":0,"product_id":1000,"product_name":"积分","validity_date":20160210,"valid_balance":1745700,"card_id":8668083660000001017,"account_balance":1745700}]}}}}
			##{"ppcs_cardsingletopup_add_response"=>{"res_timestamp"=>20160411140644, "res_sign"=>"9EFBFD4D562A5472E5F8B334F20BC45E", "trans_no"=>"0003950251", "result_info"=>{"amount"=>1000, "prdt_no"=>"0001", "validity_date"=>20170210, "top_up_way"=>1, "valid_balance"=>201771, "card_id"=>8668083660000001017, "account_balance"=>211771, "desn"=>""}, "order_id"=>"999990053990001_146035491139"}}
     		 result_info  = res_data["ppcs_cardsingletopup_add_response"]["result_info"]
     		 import_money = result_info["amount"].to_f/100
     		 balance = result_info["account_balance"]/100

     		 Ecstore::MemberAdvance.create(:member_id=>@user.member_id,
										  :money=>balance,
										  :message=>"#{from},卡号:#{card_no}",
										  :mtime=>Time.now.to_i,
										  :memo=>"用户本人操作",
										  :import_money=>import_money,
										  :explode_money=>0,
										  :member_advance=>balance,
										  :shop_advance=>balance,
										  :disabled=>'false')
			@user.update_attribute :advance, balance
			return {import_money: import_money, balance: balance}

	  #       status = case res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["product_stat"]
	  #         		when 0
	  #         			 '正常'
	  #         		when 1
	  #         			'挂失'          
	  #         		when 2
	  #         			'冻结'          
	  #         		when 3
	  #        			'作废'          
	  #         		else 
	  #         			'未知'          
	  #       end
	  #        #   message = '卡号：' + card_id + ';  认证日期：' + e.data.card_cardinfo_get_response.card_info.validity_date +';  余额：' + parseFloat(msg.account_balance / 100) + '元' + ';  产品名称：' + msg.product_name + ';  可用余额：' + parseFloat(msg.valid_balance / 100) + '元' + ';  产品有效期：' + msg.validity_date + ';  产品状态：' + state;
	  #       balance = res_data["card_cardinfo_get_response"]["card_info"]["card_product_info_arrays"]["card_product_info"][0]["valid_balance"]
	  #       balance = (balance.to_f)/100			
			
		end
	end

	def send_message (message)
		# begin
		# 	@weixin_log ||= Logger.new('log/weixin.log')

		# 	text = "您的昌麒会员卡#{@card.no}已激活,如有疑问请致电客服400-826-4568[CQ昌麒]"
		# 	# if weixin.send(@card.member_card.user_tel,text)
		# 	# 	tel = @card.member_card.user_tel
		# 	# 	@weixin_log.info("[#{@user.login_name}][#{Time.now}][#{tel}]#{text}")
		# 	# end
		# rescue
		# 	@weixin_log.info("[#{@user.login_name}][#{Time.now}]激活会员卡,发送微信失败")
		# end
	end
end
