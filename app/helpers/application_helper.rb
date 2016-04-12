#encoding:utf-8
module ApplicationHelper

  def show_error_message(message = I18n.t('activerecord.errors.messages.blank'))
    ['<small class="error">', message, '</small>'].join.html_safe
  end

  def flash_class(type)
    { notice: 'success',
      alert:  'info',
      error:  'warning' }[type]
    end

	def getColumnValue(conf,obj)
			attrs = conf.split(".")
			if attrs.length ==1
				tmp = obj.send(conf)
			else
				length = attrs.length - 1
				for i in 0..length do
					if i == 0
						if attrs[i].include? "@"
							meth = attrs[i].split("@")
							tmp = obj.send meth[0],meth[1]
						else
							tmp = obj.send attrs[i]
						end
					else
						if attrs[i].include? "@"
							meth = attrs[i].split("@")
							tmp = tmp.send meth[0],meth[1] if !tmp.nil?
						else
							tmp = tmp.send(attrs[i]) if !tmp.nil?
						end
					end
				end
			end
		return tmp
	end




	def truncate2(content,options={})
                 return nil unless content

                 options = {:length=>13}.merge(options)
                 length = options[:length].to_f
                 content = strip_tags(content).gsub(/&[a-zA-Z]{1,10};/,'').strip
                 
                 len = 0.0
                 index = 0
                 content.scan(/./).each_with_index do |c,i|
                    if c.ord <= 255
                      len += 0.5
                    else
                      len +=1
                    end
                    if len >= length
                      index = i
                      break;
                    end
                 end

                 if index>0
                   content.slice(0,index)+'...'
                 else
                   content
                 end
      end

      def good_path_ext(good,options=nil)
             good_path(good.bn)
      		# if good.bn >= "13000011"
      		# 	good_path(good.bn,options)
      		# else
      		# 	"/product-#{good.goods_id}.html"
      		# end
      end

      def check_suit(line_items = [])
          line_items.select { | line_item| line_item.good.is_suit? }.size > 0
      end

      def page_title
        (content_for :title).present? ? (content_for :title) : '昌麒投资'
      end

      def meta_keywords
        (content_for :keywords).present? ? (content_for :keywords) : '昌麒投资'
      end

      def meta_description
        (content_for :description).present? ? (content_for :description) : '昌麒投资'
      end

  def token_fieldes
    hidden_field_tag(:token_fieldes, (@token_fieldes ||= (session[:authenticity_token] =
        Digest::SHA1.hexdigest((Time.now.to_i + rand(0xffffff)).to_s)[0..39])))
  end
end
