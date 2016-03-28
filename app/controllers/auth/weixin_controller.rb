require 'digest/md5'
require 'hashie'
require 'pp'
class Auth::WeixinController < ApplicationController
	skip_before_filter :authorize_user!

	def index 
		auth_ext = Ecstore::AuthExt.find_by_id(cookies.signed[:_auth_ext].to_i) if cookies.signed[:_auth_ext]
		session[:from] = "external_auth"
		
		if auth_ext&&!auth_ext.expired?&&auth_ext.provider == 'weixin'
			if auth_ext.account.nil?
				cookies.delete :_auth_ext
				redirect_to  Weixin.authorize_url
			else
				sign_in(auth_ext.account)
				redirect_to after_user_sign_in_path
			end
		else
			redirect_to Weixin.authorize_url
		end
	end

	def callback
		 supplier_id = 1

		return redirect_to(site_path) if params[:error].present?
	    return_url= session[:return_url]
	    session[:return_url]=''

	
		token = Weixin.request_token(params[:code])
	   #return  render :text=>token.to_json

		auth_ext = Ecstore::AuthExt.where(:provider=>"weixin",
									:uid=>token.openid).first_or_initialize(
									:access_token=>token.access_token,
  #                :refresh_token=>token.refresh_token,
									:expires_at=>token.expires_at,
									:expires_in=>token.expires_in)

		if auth_ext.new_record? || auth_ext.account.nil? || auth_ext.account.user.nil?
			client = Weixin.new(:access_token=>token.access_token,:expires_at=>token.expires_at)
			# auth_user = client.get('users/show.json',:uid=>token.openid)
			#return  render :text=>auth_user .to_json
			#logger.info auth_user.inspect
	    	login_name = token.openid
    		#  return render :text=>login_name
			check_user = Ecstore::Account.find_by_login_name(login_name)
			
			login_name = "#{login_name}_#{rand(9999)}" if check_user

			now = Time.now

			@account = Ecstore::Account.new  do |ac|
				#account
				ac.login_name = login_name
				ac.login_password = login_name[0,6]#'123456'
		  		ac.account_type ="member"
		  		ac.createtime = now.to_i
		  		# auth_ext
		  		ac.auth_ext = auth_ext

        		ac.supplier_id = supplier_id        		
	  		end
	  		Ecstore::Account.transaction do
  				if @account.save!(:validate => false)
		  			@user = Ecstore::User.new do |u|
			  			u.member_id = @account.account_id
			  			u.email = "weixin_user#{rand(9999)}@anonymous.com"
			  			#u.sex = case auth_user.gender when 'f'; '0'; when 'm'; '1'; else '2'; end if auth_user
			  			u.member_lv_id = 1
			  			u.cur = "CNY"
			  			u.reg_ip = request.remote_ip
			  			#u.addr = auth_user.location || auth_user.loc_name if auth_user
			  			u.regtime = now.to_i
			  		end
		  			@user.save!(:validate=>false)
		  			sign_in(@account,'1')
		  			return redirect_to "/vip"
		  		end
	  		end

		else
			sign_in(auth_ext.account,'1')
			# return redirect_to "/member/new?return_url=#{redirect}"
		    if return_url
	          redirect = return_url
	      	else
		      redirect = after_user_sign_in_path
		    end
		    if @user
		    	if @user.member_lv_id<2
			    	redirect_to "/vip"
			    end		    	
		    end
		    redirect_to redirect
		end
	#rescue
	#	redirect_to(site_path)
	end

	def cancel
	end
end