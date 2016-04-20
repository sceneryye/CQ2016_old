module SessionsHelper
	def current_account
		return @account unless @account.nil?
		if cookies["MEMBER"].present?
			account_id = cookies["MEMBER"].split("-").first
			@account ||= Account.find_by_account_id(account_id)
		end
	end

	def current_account=(account)
		@account = account
	end
	
	def signed_in?
		!current_account.nil?
	end

	def sign_in(account,remember_me = nil)
	   current_account = account
         cookies.signed[:_auth_ext] =  account.auth_ext.id if account.auth_ext
         account.user.increment!(:login_count)  if  account.user &&  !account.user.new_record?
         #cookie for ecstore
         expires = nil
         expires = 1.week.from_now if remember_me == "1"
         if Rails.env == "production"
	         cookies[:MEMBER] = {:value=>account.gen_secret_string_for_cookie,:expires=>expires,:domain=>'.cq2016.cc'}
	         cookies[:loginName] = {:value=>account.login_name,:expires=>expires,:domain=>'.cq2016.cc'}
	         cookies[:UNAME] = {:value=>account.login_name,:expires=>expires,:domain=>'.cq2016.cc'}
	         cookies[:MLV] = {:value=>account.user.member_lv_id,:expires=>expires,:domain=>'.cq2016.cc'}
	         cookies[:CUR] = {:value=>account.user.cur,:expires=>expires,:domain=>'.cq2016.cc'}
	         cookies[:LANG] = {:value=>account.user.lang,:expires=>expires,:domain=>'.cq2016.cc'}
	       else
	   	     cookies[:MEMBER] = {:value=>account.gen_secret_string_for_cookie,:expires=>expires}
	         cookies[:loginName] = {:value=>account.login_name,:expires=>expires}
	         cookies[:UNAME] = {:value=>account.login_name,:expires=>expires}
	         cookies[:MLV] = {:value=>account.user.member_lv_id,:expires=>expires}
	         cookies[:CUR] = {:value=>account.user.cur,:expires=>expires}
	         cookies[:LANG] = {:value=>account.user.lang,:expires=>expires}
	   end
	end

	def sign_out
		current_account = nil
		[:MEMBER,:loginName,:UNAME,:MLV,:CUR,:LANG].each do |e|
			if Rails.env == "production"
				cookies.delete(e.to_s,:domain=>".cq2016.cc")
			else
				cookies.delete(e.to_s)
			end
		end
	end

	def after_user_sign_in_path
		root_path
	end

	def login_path
		subdomain = "cq2016"
  		subdomain = "www" if Rails.env == "production"
  		return_url = request.url
  		return_url = request.env["HTTP_REFERER"] if request.xhr?

  		

    cookies[:unlogin_url] = {:value=>return_url,:domain=>".cq2016.cc"}

    #"http://#{subdomain}.#{request.domain}/passport-login.html"
    "/login"
	end

	def goto_login_path
		if request.xhr?
			render :js=>"window.location.href = '#{login_path}'"
		else
			redirect_to login_path
		end
	end

	def site_path
		return "http://www.cq2016.cc/" if Rails.env == "development"
		"http://www.cq2016.cc/"
	end

	def site
		return "http://www.cq2016.cc" if Rails.env == "development"
		"http://www.cq2016.cc"
	end


	private 

	  def authorize_user!

	#  	return true  if params[:agent] == "mobile"

	  	token = params[:token]
	  	if token.present?
		  	@access_log ||=  Logger.new("log/access.log")
		  	@access_log.info("[#{Time.now}] : #{request.url}")
		  	return true
		end


	  	return true if  current_account
#	  	return true if  session[:admin_id]
	  	# return true if  Rails.env == "development"
	  	if cookies["MEMBER"]
		  	account_id = cookies["MEMBER"].split("-").first
		  	account = Account.find_by_account_id(account_id)
		  	if account
		  		secret_string = account.gen_secret_string_for_cookie
		  		# sign_in(account) if secret_string.split("-")[0..-2] == cookies["MEMBER"].split("-")[0..-2]
				return true if secret_string.split("-")[0..-2] == cookies["MEMBER"].split("-")[0..-2]
				else
					goto_login_path
				end
			else
				goto_login_path
			end
	  end

	  def authorize_admin!

	#  	return true  if params[:agent] == "mobile"

	  	token = params[:token]
	  	if token.present?
		  	@access_log ||=  Logger.new("log/access.log")
		  	@access_log.info("[#{Time.now}] : #{request.url}")
		  	return true
		end


	  	return true if  current_account
	  	return true if  session[:admin_id]
	  	# return true if  Rails.env == "development"	  	
	  end

	  def simple_authorize_user!
	  	return  true if  current_account
	  	if cookies["loginName"]
		  	account = Account.find_by_login_name(cookies["loginName"])
		  	if  account
		  		sign_in(account)
		  	else
		  		redirect_to login_path
		  	end
		else
			redirect_to login_path
		end
	  end

	  def finish_auth_path
	  	user_survey_path
	  end
end
