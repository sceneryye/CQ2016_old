#encoding:utf-8
require 'axlsx'

require 'digest'
require 'openssl'
require "base64"
require 'open-uri'
require 'typhoeus'

class Memberships::MembersController < ApplicationController
  # # test
  #     URL = 'http://116.236.192.117:8080/aop/rest'
  #     MER_ID = '999990053990001' #'999331054990016'
  #     MERCHANT_ID = '999990053990001' #'200604000000445'
  #     #821330153990232
  #     PAY_CUR = 'CNY'
  #     APPSECRET = 'test'
  #     APP_KEY = 'test'
  #     ALG = 'DES-CBC'
  #     KEY = 'abcdefgh'
  #     IV = 'abcdefgh'
  #     PSD = '111111'
  #     PAY_URL = 'https://113.108.182.3:443/aipg/ProcessServlet'
  #     USER_NAME = '20060400000044502' #'20033100001566604'
  #     USER_PASS = '111111'
  #     PRIVATE_FILE ='20060400000044502.p12'# '20033100001566604.p12'#
  #----

#验签版本号:1


#响应密钥:800001671aopres201605051747582BW2M3L6

   # product
      URL = 'http://116.228.223.212:7001/aop/rest'
      MER_ID = '999331054990016'
      MERCHANT_ID = '200604000000445'
      PAY_CUR = 'CNY'
      APPSECRET = '800001671aopreq20160505174758rygZwewN'
      APP_KEY = '80000167'
      ALG = 'DES-CBC'
      KEY = '6223e3c4'
      IV = '6223e3c4'
      PSD = '111111'

      PAY_URL = 'https://tlt.allinpay.com:443/aipg/ProcessServlet'
      USER_NAME = '20033100001566604'
      USER_PASS = '111111'
      PRIVATE_FILE ='20033100001566604.p12'
  #----
      PUBLIC_FILE = 'allinpay-pds.cer'
	
	before_filter :authorize_user!
	# layout 'standard'
	layout "application"

	before_filter do
		clear_breadcrumbs
		add_breadcrumb("我的昌麒",:member_path)
	end

  def idcard
      timestamps = Time.now.strftime('%Y%m%d%H%M%S')
      mer_tm = timestamps
      req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')

      options = {IDVER:{NAME: '刘龙英', IDNO: '332522195812245684',VALIDATA: '', REMARK: '单笔实时身份验证'}}


       data_hash = {INFO:{TRX_CODE: '220001', VERSION: '03', DATA_TYPE: 2, LEVEL: 5, MERCHANT_ID: MERCHANT_ID,
                    USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800',
                    MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}}.merge! options

      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK').gsub('hash','AIPG').gsub('-','_')
     
      p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("../../../../lib/#{PRIVATE_FILE}", __FILE__)), USER_PASS)
      # return render text: p12.certificate.to_pem 

      # 证书 # puts p12.certificate.to_pem 
      # 私钥  # puts p12.key.export
      key = p12.key

      pri = OpenSSL::PKey::RSA.new key.export
      #Base64.encode64(OpenSSL::PKey::RSA.new(PRIVATEKEY).sign('sha1', data.force_encoding("utf-8"))).gsub("\n", "")
      sign = pri.sign("sha1", data_xml.force_encoding("GBK"))

      # return render text: "#{sign.unpack('H*').first}"
      # pub = OpenSSL::X509::Certificate.new (File.read(File.expand_path("../../../../lib/#{PUBLIC_FILE}", __FILE__)))
      pub_key = pri.public_key
      result = pub_key.verify('sha1', sign, data_xml.force_encoding("GBK"))
      # return render text: "verify #{result ? 'successful!' : 'failed!'}"

      data_xml = data_xml.sub('</SUBMIT_TIME>',"</SUBMIT_TIME><SIGNED_MSG>#{sign.unpack('H*').first}</SIGNED_MSG>")
      # return render text: data_xml
      # request = Typhoeus::Request.new(PAY_URL, method: :post, params: data_xml, ssl_verifypeer: false, headers: {'Content-Type' =>'application/x-www-form-urlencoded'} )
      # request.run
      # return render text: request.response.to_json
      # if request.response.success?
      #   res_data_xml = Hash[*request.response.body.split("&").map{|a| a.gsub("==", "@@").split("=")}.flatten]['tn']
      # else
      #   res_data_xml = ""
      # end
    uri = URI.parse(PAY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new("/aipg/ProcessServlet")
    request.add_field('Content-Type', 'text/xml')
    #request.body = post_data.to_json
    response = http.request(request)
    res_data_xml = response.body

     #res_data_xml = RestClient.post PAY_URL, data_xml, content_type: "text/xml"

      return render text: res_data_xml
    end


  def new
   
  end


  def update
    member_params = user_params
    addr_params = user_params
   

    if @user.update_attributes(member_params.merge!(:apply_time=>Time.now))    

      addr_params.merge!(:member_id=>@user.member_id,:def_addr=>1).delete(:id_card_number)  
      @addr = MemberAddr.create(addr_params)

      redirect_to new_card_path
    else
      render "new"
    end
  end

  def advance
    @deposit = 0

    @deposit = @user.member_lv.deposit if @user.member_lv
  

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
    @paid_count = @user.orders.where(:pay_status=>'1',:status=>'active').size
    @history_count = @user.orders.where("pay_status='1' and (ship_status = '1' or status <> 'active')").size
		add_breadcrumb("我的昌麒")
	end

	def orders
    pay_status = params[:pay_status]
    status = params[:status]
    if  pay_status.present?
      condition = "pay_status='#{pay_status}'"
      if pay_status=='1'
        @paid ='disabled'
      else
        @unpaid='disabled'
      end

    else
      condition = "pay_status='1' and (ship_status = '1' or status <> 'active')"
      @history ='disabled'
    end
		@orders = @user.orders.where(condition).order('order_id DESC').paginate(:page=>params[:page],:per_page=>10)

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
   def user_params
      params.require(:user).permit(:name,:card_num,:area,:mobile,:addr,:sex,:id_card_number,:province, :city, :district,)
    end

	
end
