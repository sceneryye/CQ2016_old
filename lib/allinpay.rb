require 'digest/md5'
require 'openssl'
require 'base64'
require 'rest-client'
module Allinpay
  URL = 'http://116.236.192.117:8080/aop/rest'
  MER_ID = '999331054990016'#'999990053990001'
  MERCHANT_ID = '999331054990016'#'200604000000445'
  #821330153990232
  PAY_CUR = 'CNY'
  APPSECRET = 'test'
  APP_KEY = 'test'
  ALG = 'DES-CBC'
  KEY = 'abcdefgh'
  IV = 'abcdefgh'
  PSD = '111111'
  #PAY_URL = 'https://113.108.182.3:443/aipg/ProcessServlet'
  PAY_URL = 'https://tlt.allinpay.com:443/aipg/ProcessServlet'
  USER_NAME = '20033100001566604' #'20060400000044502'
  USER_PASS = '111111'
  CER_FILE = '20033100001566604.p12'#'20060400000044502.p12'

  def timestamps
    Time.now.strftime('%Y%m%d%H%M%S')
  end

  def public_params method, timestamp
    data = {app_key: APP_KEY, method: method, timestamp: timestamp, v: '1.0', sign_v: '1',
      format: 'json'}
    end

    def create_sign_for_allin hash, appsecret
      str = hash.select{|key, val| val.present?}.sort{|a, b| a[0] <=> b[0]}.map{|arr|arr[0].to_s + arr[1].to_s}.join('')
      unencrypt_str = appsecret + str + appsecret
      Rails.logger.info "----------------unencrypt_str = #{unencrypt_str}"
      sign = (Digest::MD5.hexdigest unencrypt_str).upcase
    end

    def des_encrypt message, timestamp
      str = timestamp + 'aop' + message
      # str = "20160325161914aop8668083660000001017"
      des = OpenSSL::Cipher.new(ALG)
      des.encrypt
      des.key = KEY
      des.iv = IV
      cipher = des.update(str)
      cipher << des.final
      Rails.logger.info "------------------en_pwd = #{Base64.encode64(cipher)}"
      Base64.encode64(cipher)
    end

    def card_active order_id, card_id, type, desc = 'active card'
      data_hash = (public_params 'allinpay.ppcs.cardsingleactive.add', timestamps).merge({order_id: order_id, card_id: card_id, type: type, desc: desc})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      # url = URL + '?' + send_data.to_param
      # p12 = OpenSSL::PKCS12.new(File.read(File.expand_path('../20060400000044502.p12', __FILE__)), '111111')
      # RestClient::Request.execute(method: :get, url: url,
        # :ssl_client_cert => p12.certificate,
        # ssl_ca_file: p12.key.to_s,
        # :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
        res_data_json = RestClient.get URL, {params: send_data}
      end

      def topup_single_card order_id, card_id, prdt_no, amount, top_up_way, opr_id, desn = 'topup card'
        data_hash = (public_params 'allinpay.ppcs.cardsingletopup.add', timestamps).merge({order_id: order_id, card_id: card_id,
          prdt_no: prdt_no, amount: amount, top_up_way: top_up_way, opr_id: opr_id, desn: desn})
        Rails.logger.info "--------desn = #{desn}"
        sign = create_sign_for_allin data_hash, APPSECRET
        send_data = data_hash.merge({sign: sign})
        res_data_json = RestClient.get URL, {params: send_data}
      end

      def pay_with_password order_id,  mer_order_id, payment_id, amount, card_id, password, pay_cur = PAY_CUR, type = '01', options = {}
        mer_tm = timestamps
      # mer_tm = '20160325161914'
      data_hash = (public_params 'allinpay.card.paywithpassword.add', mer_tm).merge({pay_cur: pay_cur, type: type, mer_id: MERCHANT_ID, mer_tm: mer_tm, order_id: order_id, mer_order_id: mer_order_id, payment_id: payment_id, amount: amount}).merge options
      encrypt_card_id = des_encrypt card_id, mer_tm
      encrypt_password = des_encrypt password, mer_tm
      Rails.logger.info encrypt_card_id
      data_hash.merge!({card_id: encrypt_card_id, password: encrypt_password})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_reset_password order_id, card_id, password, options = {}
      mer_tm = timestamps
      data_hash = (public_params 'allinpay.ppcs.cardpassword.rest', mer_tm).merge({order_id: order_id, card_id: card_id}).merge options
      encrypt_password = des_encrypt password, mer_tm
      data_hash.merge!({password: encrypt_password})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_freeze order_id, card_id, prdt_id, reason
      data_hash = (public_params 'allinpay.ppcs.cardproductfreeze.add', timestamps).merge({order_id: order_id, card_id: card_id, prdt_id: prdt_id, reason: reason})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_unfreeze order_id, card_id, prdt_id, reason
      data_hash = (public_params 'allinpay.ppcs.cardproductunfreeze.add', timestamps).merge({order_id: order_id, card_id: card_id, prdt_id: prdt_id, reason: reason})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end


    def card_report_loss order_id, card_id, id_type, id_no, reason
      data_hash = (public_params 'allinpay.ppcs.cardreportloss.add', timestamps).merge({order_id: order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_cancel_loss order_id, card_id, id_type, id_no, reason
      data_hash = (public_params 'allinpay.ppcs.cardcancelloss.add', timestamps).merge({order_id: order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason})
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_get_info card_id, password
      mer_tm = timestamps
      data_hash = (public_params 'allinpay.card.cardinfo.get', mer_tm).merge(card_id: card_id)
      encrypt_password = des_encrypt password, mer_tm
      data_hash.merge!(password: encrypt_password)
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.get URL, {params: send_data}
    end

    def card_get_trade_log begin_date, end_date, card_id, password, page_no, page_size
      mer_tm = timestamps
      data_hash = (public_params 'allinpay.card.txnlogByCardId.search', mer_tm).merge(begin_date: begin_date, end_date: end_date, card_id: card_id, page_no: page_no, page_size: page_size)
      encrypt_password = des_encrypt password, mer_tm
      data_hash.merge!(password: encrypt_password)
      sign = create_sign_for_allin data_hash, APPSECRET
      send_data = data_hash.merge({sign: sign})
      res_data_json = RestClient.post URL, send_data
    end

    def id_card_verify name, id_no
       mer_tm = timestamps
      req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
      data_hash = {TRX_CODE: '220001', VERSION: '03', DATA_TYPE: 2, LEVEL: 9, USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800', MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}.merge! options
      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
      sign = create_sign_for_another data_xml
      data_hash.merge! sign: sign
      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
      Rails.logger.info data_xml
      res_data_xml = RestClient.post PAY_URL, data_xml, content_type: :xml

#       INFO  TRX_CODE  交易代码  C(1, 20)  220001  否
#   VERSION 版本  C(2)  03  否
#   DATA_TYPE 数据格式  N(1)  2：xml格式 否
#   LEVEL 处理级别  N(1)  0-9  0优先级最低，默认为5  否
#   MERCHANT_ID 商户号 C(15)   否
#   USER_NAME 用户名 C(1,20)   否
#   USER_PASS 用户密码      否
#   REQ_SN  交易批次号 C(40) 商户号+时间+自定义流水  否
#   SIGNED_MSG  签名信息  C   否
# IDVER NAME  姓名  C(100)    非空
#   IDNO  身份证号  C (1,22)    非空
#   VALIDATE  有效期 C(8)  YYYYMMDD  可空
#   REMARK  备注  C (1,50)  预留  可空

    end

    def pay_for_another options
      mer_tm = timestamps
      req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
      data_hash = {TRX_CODE: '100014', VERSION: '03', DATA_TYPE: 2, LEVEL: 9, USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800', MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}.merge! options
      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
      sign = create_sign_for_another data_xml
      data_hash.merge! sign: sign
      data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
      Rails.logger.info data_xml
      res_data_xml = RestClient.post PAY_URL, data_xml, content_type: :xml
      # res_data_xml = RestClient::Request.execute(method: post, ) PAY_URL, data_xml, content_type: :xml
    end

    def create_sign_for_another xml
      p12 = OpenSSL::PKCS12.new(File.read(File.expand_path("../#{CER_FILE}", __FILE__)), USER_PASS)
      key = p12.key
      pri = OpenSSL::PKey::RSA.new key.to_s
      sign = pri.sign("sha1", xml)
    end
  end












