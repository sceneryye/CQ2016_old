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
				@user.update_attribute :card_validate,'true'
				@card.update_attribute :use_status,true
				@card.update_attribute :used_at,Time.now
				@card.member_card.update_attribute :user_id,@user.member_id
				@card.member_card.update_attribute :member_id,@user.member_id

				#发微信通知
				begin
					@weixin_log ||= Logger.new('log/weixin.log')

					text = "您的昌麒会员卡#{@card.no}已激活,如有疑问请致电客服400-826-4568[CQ昌麒]"
					# if weixin.send(@card.member_card.user_tel,text)
					# 	tel = @card.member_card.user_tel
					# 	@weixin_log.info("[#{@user.login_name}][#{Time.now}][#{tel}]#{text}")
					# end
				rescue
					@weixin_log.info("[#{@user.login_name}][#{Time.now}]激活会员卡,发送微信失败")
				end

				Ecstore::CardLog.create(:member_id=>@user.member_id,
	                                                :card_id=>@card.id,
	                                                :message=>"会员卡激活,用户本人操作")
				redirect_to cards_path

			end
		else
			return render text: '会员卡无法激活'
		end
	end

  	def login

	    password = params[:password]
	    message = params[:message]

	    card_info = card_info(message,password)

		if card_info["error"]
			return render text: card_info
		else
			redirect_to card_path(0)
		end
  	end

  	def show
  		

		# if params[:card].has_key?(:card_no)
		# 	@card = Ecstore::Card.find_by_no(params[:card][:card_no])
		# 	if @card
		# 		render "memberships/cards/confirm_activation"
		# 	else
		# 		render "memberships/cards/activation"
		# 	end
		# end

		# if params[:card].has_key?(:user_tel)
			
		# end
	end

  	def recharge () end

  	def topup
	    #data = params.permit(:order_id, :card_id, :prdt_no, :amount, :top_up_way, :opr_id, :desn)
	    order_id = params[:order_id]
	    card_id = params[:card_id]
	    prdt_no = params[:prdt_no]
	    amount = params[:amount]
	    top_up_way = params[:top_up_way]
	    opr_id = params[:opr_id]
	    desn = params[:desn]
	    res_data = ActiveSupport::JSON.decode topup_single_card(order_id, card_id, prdt_no, amount, top_up_way, opr_id, desn)
	    Rails.logger.info res_data
	    render json: {data: res_data}
	end

  	def edit () end

  	def update
	    card_id = @user.card_num
	    old_pwd = params[:old_pwd]
	    new_pwd = params[:new_pwd]

	    card_info = card_info('修改密码',old_pwd)

	    if card_info[:error]
			return render text: '原密码不正确'
		else
			# reset_password
		    order_id = get_order_id
		    res_data = ActiveSupport::JSON.decode card_reset_password(order_id, card_id, new_pwd)
		    Rails.logger.info res_data
		    render json: {data: res_data}
		    session[:password] = params[:new_pws]
		end	
	end

	def index
		@tradings = Ecstore::CardTradingLog.paginate(:page=>params[:page],:per_page=>20)
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
	    order_id = params[:order_id]
	    mer_order_id = params[:mer_order_id]
	    payment_id = params[:payment_id]
	    amount = params[:amount]
	    card_id = params[:card_id]
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
	

	def confirm_activation
		@card = Ecstore::Card.find_by_no(params[:card][:no])
		if @card.card_type == "A"
			sms_code = params[:sms_code]

			unless @card.can_use?
				@card.errors.add(:sms_code, "该卡不能激活，请检查卡状态。")
				render "memberships/cards/activation/validate"
				return
			end


			if sms_code.blank?
				@card.errors.add(:sms_code, "请输入激活码")
				render "memberships/cards/activation/validate"
				return
			end
			
			if @user.check_sms(sms_code)
				if @user.mobile != @card.member_card.user_tel
					render "memberships/cards/activation/update_mobile"
				else
					render "memberships/cards/activation/confirm"
				end

				return
			else
				@card.errors.add(:sms_code, "激活码错误或者失效，请重新发送")
				render "memberships/cards/activation/validate"
				return
			end
		end

		if @card.card_type == "B"
			password = params[:card][:password]

			unless @card.can_use?
				@card.errors.add(:password, "该卡不能激活，请检查卡状态。")
				render "memberships/cards/activation/validate"
				return
			end


			if password.blank?
				@card.errors.add(:password, "请输入密码")
				render "memberships/cards/activation/validate"
				return
			end

			if @card.password != password
				if @card.try_password_times < 4
					@card.increment! :try_password_times
					@card.errors.add(:password, "密码错误,剩#{ 5 - @card.try_password_times }余次尝试机会。")
					render "memberships/cards/activation/validate"
				else
					@card.update_attribute :status,"锁定"
					render "memberships/cards/activation/locked"
				end
			else
				render "memberships/cards/activation/mobile"
				return
			end

		end
	end

	def validate_activation
		if params[:card][:no].blank?
			@error = "请输入会员卡号"
			render "memberships/cards/activation"
			return
		end

		@card = Ecstore::Card.find_by_no(params[:card][:no])

		if @card.nil?
			@error = "会员卡号不存在"
			render "memberships/cards/activation"
			return
		end

		if @card.used?
			@error = "您输入的卡号已激活，请核实"
			render "memberships/cards/activation"
			return
		end

		if @card.can_use?
			tel = @card.member_card.buyer_tel
			sms_code = rand(1000000).to_s(16)
			text = "您的会员卡验证码是：#{sms_code}，如此条验证码非您本人申请，请立即致电客服400-826-4568核实[CQ昌麒]"
			@sms_log ||= Logger.new('log/sms.log')
			begin
				if Sms.send(tel,text)
					@user.update_attribute :sms_code, sms_code
					@sms_log.info("[#{@user.login_name}][#{Time.now}][#{tel}]发送手机验证码: #{sms_code}")
				end
			rescue Exception => e
				@sms_log.info("[#{@user.login_name}][#{Time.now}][#{tel}]发送手机验证码失败:#{e}")
			end
			
			render "memberships/cards/activation/validate"
		else
			@error = "您输入的卡号不能激活"
			render "memberships/cards/activation"
			return
		end
	end

	private
	def card_params
	    params.require(:card).permit(:card_num,:card_pwd)
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

	        				balance = card_info[:balance]
				Ecstore::MemberAdvance.create(:member_id=>@user.member_id,
												  :money=>@card.value,
												  :message=>"#{from},卡号:#{@card.no}",
												  :mtime=>Time.now.to_i,
												  :memo=>"用户本人操作",
												  :import_money=>@card.value,
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
end
