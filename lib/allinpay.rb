require 'digest/md5'
require 'openssl'
require 'base64'
require 'rest-client'
module Allinpay
  URL = 'http://116.236.192.117:8080/aop/rest'
  MER_ID = '999990053990001'
  PAY_CUR = 'CNY'
  APPSECRET = 'test'
  APP_KEY = 'test'
  ALG = 'DES-CBC'
  KEY = 'abcdefgh'
  IV = 'abcdefgh'
  PSD = '111111'
  CARD_ID = '8668083660000001017'

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
      data_hash = (public_params 'allinpay.card.paywithpassword.add', mer_tm).merge({pay_cur: pay_cur, type: type, mer_id: MER_ID, mer_tm: mer_tm, order_id: order_id, mer_order_id: mer_order_id, payment_id: payment_id, amount: amount}).merge options
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
  end












