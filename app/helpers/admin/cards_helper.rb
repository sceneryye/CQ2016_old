#encoding:utf-8
module Admin::CardsHelper

	def unsold_card_status_options
		{ '正常'=>'正常','作废'=>'作废' }
	end

	def sold_card_status_options
		{ '正常'=>'正常','锁定'=>'锁定' }
	end

	def search_options
		{"会员名"=>'login_name',"手机号码"=>"mobile"}
	end

	def card_sale_status_options
		{"未销售"=>0,"已销售"=>1}
	end

	def card_use_status_options
		{"未使用"=>0,"已使用"=>1}
	end

	def sold_card_pay_status_options
		{"未付款"=>false,"付款"=>true}
	end

	def level(val)
		case val
			when 'A'; "贵族至尊卡"
			else 'B'; "万事如意卡"
		end
	end

end
