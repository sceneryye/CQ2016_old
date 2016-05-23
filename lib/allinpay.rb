require 'digest/md5'
require 'openssl'
require 'base64'
require 'rest-client'

module Allinpay
  PAY_CUR = 'CNY'
  PUBLIC_FILE = 'allinpay-pds.cer'
  SIGN_V = '1'

  # # test
  #   URL = 'http://116.236.192.117:8080/aop/rest'
  #   MER_ID = '999990053990001'
  #   #821330153990232
  #   APPSECRET = 'test'
  #   APP_KEY = 'test'
  #   KEY = 'abcdefgh'
  #   IV = 'abcdefgh'
  #   PRDT_NO = "0001"

  #   PAY_URL = 'https://113.108.182.3:443/aipg/ProcessServlet'
  #   USER_NAME = '20060400000044502'
  #   USER_PASS = '111111'
  #   PRIVATE_FILE ='20060400000044502.p12'    
  #   MERCHANT_ID = '999990053990001' #'200604000000445'
  # #----

  # product
      URL = 'http://116.228.223.212:7001/aop/rest'
      MER_ID = '999331054990016'
      APPSECRET = '800001671aopreq20160505174758rygZwewN'
      APP_KEY = '80000167' 
      PRDT_NO = "0002"
    
      KEY = '6223e3c4'
      IV = '6223e3c4'    
      
      MERCHANT_ID = '200604000000445'
      PAY_URL = 'https://tlt.allinpay.com:443/aipg/ProcessServlet'
      USER_NAME = '20033100001566604'
      USER_PASS = '111111'
      PRIVATE_FILE ='20033100001566604.p12'
      #验签版本号:1
      #请求密钥:800001671aopreq20160505174758rygZwewN
      #响应密钥:800001671aopres201605051747582BW2M3L6
  #----      

  def timestamps
    Time.now.strftime('%Y%m%d%H%M%S')
  end

  def public_params method, timestamp
    data = {app_key: APP_KEY, method: method, timestamp: timestamp, v: '1.0', sign_v: SIGN_V, format: 'json'}
  end

  def create_sign_for_allin hash
    str = hash.select{|key, val| val.present?}.sort_by{ |key,val| key }.collect{|key,val| "#{key}#{val}" }.join('')
    
    unencrypt_str = APPSECRET + str + APPSECRET
    Rails.logger.info "----------------unencrypt_str = #{unencrypt_str}"
    sign = (Digest::MD5.hexdigest unencrypt_str).upcase
  end

  def des_encrypt message, timestamp
    str = timestamp + 'aop' + message
    # str = "20160325161914aop8668083660000001017"
    des = OpenSSL::Cipher.new('DES-CBC')
    des.encrypt
    des.key = KEY
    des.iv = IV
    cipher = des.update(str)
    cipher << des.final
    Rails.logger.info "------------------en_pwd = #{Base64.encode64(cipher)}"
    Base64.encode64(cipher)
  end

  def card_get_info card_id, password
    mer_tm = timestamps
    encrypt_password = des_encrypt password, mer_tm
    data_hash = (public_params 'allinpay.card.cardinfo.get', mer_tm).merge(card_id: card_id, password: encrypt_password)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end


  def card_active order_id, card_id, type, desc = 'active card'
    data_hash = (public_params 'allinpay.ppcs.cardsingleactive.add', timestamps).merge({order_id: order_id, card_id: card_id, type: type, desc: desc})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
    end

  def topup_single_card order_id, card_id, amount, top_up_way, opr_id, desn = 'topup card'
    data_hash = (public_params 'allinpay.ppcs.cardsingletopup.add', timestamps).merge({order_id: order_id, card_id: card_id,
      prdt_no: PRDT_NO, amount: amount, top_up_way: top_up_way, opr_id: opr_id, desn: desn})
    Rails.logger.info "--------desn = #{desn}"
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def pay_with_password order_id,  mer_order_id, payment_id, amount, card_id, password, pay_cur = PAY_CUR, type = '01', options = {}
    mer_tm = timestamps
    encrypt_card_id = des_encrypt card_id, mer_tm
    encrypt_password = des_encrypt password, mer_tm
    data_hash = (public_params 'allinpay.card.paywithpassword.add', mer_tm).merge({pay_cur: pay_cur, type: type, mer_id: MER_ID, mer_tm: mer_tm, order_id: order_id, mer_order_id: mer_order_id, payment_id: payment_id, amount: amount}).merge options
    
    data_hash.merge!({card_id: encrypt_card_id, password: encrypt_password})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_reset_password order_id, card_id, password, options = {}
    mer_tm = timestamps
    data_hash = (public_params 'allinpay.ppcs.cardpassword.rest', mer_tm).merge({order_id: order_id, card_id: card_id}).merge options
    encrypt_password = des_encrypt password, mer_tm
    data_hash.merge!({password: encrypt_password})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_freeze order_id, card_id, reason
    data_hash = (public_params 'allinpay.ppcs.cardproductfreeze.add', timestamps).merge({order_id: order_id, card_id: card_id, prdt_id: PRDT_NO, reason: reason})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_unfreeze order_id, card_id, reason
    data_hash = (public_params 'allinpay.ppcs.cardproductunfreeze.add', timestamps).merge({order_id: order_id, card_id: card_id, prdt_id: PRDT_NO, reason: reason})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_report_loss order_id, card_id, id_type, id_no, reason
    data_hash = (public_params 'allinpay.ppcs.cardreportloss.add', timestamps).merge({order_id: order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_cancel_loss order_id, card_id, id_type, id_no, reason
    data_hash = (public_params 'allinpay.ppcs.cardcancelloss.add', timestamps).merge({order_id: order_id, card_id: card_id, id_type: id_type, id_no: id_no, reason: reason})
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.get URL, {params: send_data}
  end

  def card_get_trade_log begin_date, end_date, card_id, password, page_no, page_size
    mer_tm = timestamps
    data_hash = (public_params 'allinpay.card.txnlogByCardId.search', mer_tm).merge(begin_date: begin_date, end_date: end_date, card_id: card_id, page_no: page_no, page_size: page_size)
    encrypt_password = des_encrypt password, mer_tm
    data_hash.merge!(password: encrypt_password)
    sign = create_sign_for_allin data_hash
    send_data = data_hash.merge({sign: sign})
    res_data_json = RestClient.post URL, send_data
  end

  def id_card_verify name, id_no
    mer_tm = timestamps
    req_sn = MERCHANT_ID + mer_tm + rand(1000).to_s.ljust(4, '0')
    data_hash = {TRX_CODE: '220001', VERSION: '03', DATA_TYPE: 2, LEVEL: 5, MERCHANT_ID: MERCHANT_ID,
                  USER_NAME: USER_NAME, USER_PASS: USER_PASS, REQ_SN: req_sn, BUSINESS_CODE: '10800',
                  MERCHANT_ID: MERCHANT_ID, SUBMIT_TIME: mer_tm}.merge! options
    data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
    sign = create_sign_for_another data_xml
    data_hash.merge! sign: sign
    data_xml = data_hash.to_xml.sub('UTF-8', 'GBK')
    Rails.logger.info data_xml
    res_data_xml = RestClient.post PAY_URL, data_xml, content_type: :xml
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












