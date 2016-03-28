#encoding:utf-8
require 'rest-client'

module ModecPay

	class Payment

		attr_accessor :mer_id, :private_key
		attr_accessor :action, :method, :charset
		attr_accessor :fields
		attr_accessor :filter
		
		attr_accessor :return_url, :notify_url
		
		attr_accessor :installment

		#  payment id in db
		attr_accessor :pay_id

		attr_accessor :pay_time, :pay_amount

		# payment subject
		attr_accessor :subject

		# payment description
		attr_accessor :body

    attr_accessor :openid, :spbill_create_ip

		# A block pass to sort_by 
		# == Example
		#   payment.sorter = Proc.new { |key,val|  key }
		# Or a Array that contain fields,specify the order
		# == Example
		#   payment.sorter = ['version','lan','sign','_charset']
		#   if extra  in fields,those extra will append to fields
		#   
		#   This is used to order fields for form
		attr_accessor :sorter 

		def initialize
			self.fields = {}
		end

		def html_form
			make_sign

			if sorter.is_a?(Proc)
			    self.fields = Hash.send :[],  self.fields.select{ |key,val|  val.present? }.sort_by(&self.sorter)
			end

			if sorter.is_a?(Array)
				_fields = self.fields.dup
				self.fields = {}
				sorter.each do |key|
					self.fields[key] = _fields.delete(key)
				end
				self.fields.merge!(_fields)  unless _fields.empty?
			end

			_filter = self.filter if self.filter.is_a?(Proc)
			_filter = proc { true }  unless _filter

			form_inputs = self.fields.select(&_filter).collect do |key,val|
				"<input type='hidden' name='#{key}' value='#{val}' />"
			end.join(" ")

			<<-FORM
				<!DOCTYPE html>
				<html>
				<head>
					<meta http-equiv="Content-Type" content="text/html; charset=#{self.charset}">
					<title>Redirecting...</title>
				</head>
				<body>
				<div>Redirecting...</div>
				<form accept-charset="#{self.charset}" action="#{self.action}" method="#{self.method}" id="pay_form">
					#{form_inputs}
				</form>
				<script type="text/javascript">
					window.onload=function(){
						document.getElementById("pay_form").submit();
					}
				</script>
				</body>
				</html>
			FORM
    end

    def html_form_wxpay
      #make_sign
      #make_pay_sign
      pre_pay

      xml = self.fields['pre_pay_xml']

      RestClient.get(self.action)
      res_data = RestClient.post self.action , xml , {:content_type => :xml}
      res_data_xml = res_data.force_encoding('utf-8').encode
      res_data_hash = Hash.from_xml(res_data_xml)

      if res_data_hash['xml']['return_code']=='SUCCESS'
        self.fields['package'] ="prepay_id=#{res_data_hash['xml']['prepay_id']}"
        make_pay_sign
      else
        self.fields['package'] = res_data_hash['xml']
      end

      _filter = self.filter if self.filter.is_a?(Proc)
      _filter = proc { true }  unless _filter

      form_inputs = self.fields.select(&_filter).collect do |key,val|
        "<input type='hidden' name='#{key}' value='#{val}' />"
      end.join(" ")

      <<-FORM
				<!DOCTYPE html>
				<html>
				<head>
					<meta http-equiv="Content-Type" content="text/html; charset=#{self.charset}">
          <script language="javascript" src="http://res.mail.qq.com/mmr/static/lib/js/jquery.js" type="text/javascript"></script>
          <script language="javascript" src="http://res.mail.qq.com/mmr/static/lib/js/lazyloadv3.js"  type="text/javascript"></script>
          <meta id="viewport" name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1; user-scalable=no;" />
					<title>Redirecting...</title>
				</head>
				<body>
      <br/>
      <div class="list_status">
        <h2 class="blue" >
          <span class="pay_icon"></span>
          <span style="color: #0abede">正在跳转到到微信支付...</span>
        </h2>
      </div>       
        <form accept-charset="#{self.charset}" action="/payments?id=#{self.pay_id}" method="post" id="pay_form">
          #{form_inputs}

        </form>
				
     <script language="javascript" type="text/javascript">
      function auto_remove(img){
          div=img.parentNode.parentNode;div.parentNode.removeChild(div);
          img.onerror="";
          return true;
      }

      function changefont(fontsize){
          if(fontsize < 1 || fontsize > 4)return;
          $('#content').removeClass().addClass('fontSize' + fontsize);
      }

      function onBridgeReady(){
         WeixinJSBridge.invoke(
             'getBrandWCPayRequest', {
                 "appId" : "#{self.fields['appid']}", //公众号名称，由商户传入
                  "timeStamp" : "#{self.fields['time_stamp']}", //时间戳
                  "nonceStr" : "#{self.fields['nonce_str']}", //随机串
                  "package" : "#{self.fields['package']}",//扩展包
                  "signType" : "#{self.fields['sign_type']}", //微信签名方式:1.sha1;2.md5
                  "paySign" : "#{self.fields['pay_sign']}" //微信签名
             },
             function(res){
                var error_message="";
                alert(res)
                if(res.err_msg != "get_brand_wcpay_request:ok") { 
                  error_message = "?error_message="+res.err_desc;                  
                } 
                window.location = "/payments/#{self.fields['out_trade_no']}/wxpay/callback"+error_message;
             }
         ); 
      }
      if (typeof WeixinJSBridge == "undefined"){
         if( document.addEventListener ){
             document.addEventListener('WeixinJSBridgeReady', onBridgeReady, false);
         }else if (document.attachEvent){
             document.attachEvent('WeixinJSBridgeReady', onBridgeReady); 
             document.attachEvent('onWeixinJSBridgeReady', onBridgeReady);
         }
      }else{
         onBridgeReady();
      }



      if(jQuery){
          jQuery(function(){

              var width = jQuery('body').width() * 0.87;
              jQuery('img').error(function(){
                  var self = jQuery(this);
                  var org = self.attr('data-original1');
                  self.attr("src", org);
                  self.error(function(){
                      auto_remove(this);
                  });
              });
              jQuery('img').each(function(){
                  var self = jQuery(this);
                  var w = self.css('width');
                  var h = self.css('height');
                  w = w.replace('px', '');
                  h = h.replace('px', '');
                  if(w <= width){
                      return;
                  }
                  var new_w = width;
                  var new_h = Math.round(h * width / w);
                  self.css({'width' : new_w + 'px', 'height' : new_h + 'px'});
                  self.parents('div.pic').css({'width' : new_w + 'px', 'height' : new_h + 'px'});
              });
          });
      }
            </script>
          </head>
          <body>
          
				</body>
				</html>
      FORM

    end

    def html_form_alipaywap
      make_sign

      if sorter.is_a?(Proc)
        self.fields = Hash.send :[],  self.fields.select{ |key,val|  val.present? }.sort_by(&self.sorter)
      end

      if sorter.is_a?(Array)
        _fields = self.fields.dup
        self.fields = {}
        sorter.each do |key|
          self.fields[key] = _fields.delete(key)
        end
        self.fields.merge!(_fields)  unless _fields.empty?
      end

      _filter = self.filter if self.filter.is_a?(Proc)
      _filter = proc { true }  unless _filter

      querystring = self.fields.select(&_filter).collect do |key,val|
        "#{key}=#{val}"
      end.join("&")

      error_message ='取得Token错误'

      res_data= RestClient.get(URI.encode("#{self.action}?#{querystring}"))
      res_data =URI.decode(res_data)
      res_data=res_data.split('&').first.sub('res_data=','')
      #return res_data
      if res_data

        # @@mer_id = '2088411414403176'
        #@@private_key  = 'hzh3bf969beqkqdbohdxocxlwpgr8278'
        #@@seller_account_name='maowei@iotps.com'

        self.sorter = Proc.new { |key,val| key }
        self.filter = Proc.new { |key,val| key.present? }
        #  self.sorter = ['service','req_data','partner','req_id','sec_id', 'format','v']

        request_token = Hash.from_xml(res_data)['direct_trade_create_res']['request_token']
        self.fields['req_data'] = "<auth_and_execute_req><request_token>#{request_token}</request_token></auth_and_execute_req>"
        self.fields['service'] = 'alipay.wap.auth.authAndExecute'
        self.fields['sign'] = make_sign
            #sec_id = 'MD5'
        #partner = ''
        #sign=''
        #format='xml'
        #v = '2 .0'

        querystring = self.fields.select(&_filter).collect do |key,val|
          "#{key}=#{val}"
        end.join("&")

        #return querystring
        RestClient.get(URI.encode("#{self.action}?#{querystring}"))
      #  redirect_to URI.encode("#{self.action}?#{querystring}")

      else
        return error_message
      end


    end

		private 

		#  === Example 
		#  def make_sign
		#      _sign = "secret string"
		#      self.fields['sign'] = _sign
		#  end
		def make_sign
			#warn 'TODO: Add signature to fields'
      return '' if self.fields.blank?
      _sorted = Hash.send :[],  self.fields.select{ |key,val|  val.present? && key != 'sign_type' && key != 'sign' }.sort_by{ |key,val|  key }

      unsign = _sorted.collect{ |key,val| "#{key}=#{val}" }.join("&") + self.private_key
      Digest::MD5.hexdigest(unsign)
		end

	end

end