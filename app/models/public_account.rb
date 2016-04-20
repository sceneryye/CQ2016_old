#encoding:utf-8

class PublicAccount < Base
  #include WeixinRailsMiddleware::AutoGenerateWeixinTokenSecretKey
  self.table_name = 'public_accounts'

  #attr_accessor :weixin_secret_key,:weixin_token,:supplier_id


end