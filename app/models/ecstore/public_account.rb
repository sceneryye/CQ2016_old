#encoding:utf-8

class Ecstore::PublicAccount < Ecstore::Base
  #include WeixinRailsMiddleware::AutoGenerateWeixinTokenSecretKey
  self.table_name = 'public_accounts'

  #attr_accessor :weixin_secret_key,:weixin_token,:supplier_id


end