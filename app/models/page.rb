#encoding:utf-8
class Page < AbstractPage

	extend FriendlyId
	
	friendly_id :url, :use => [:slugged, :finders]

	validates_presence_of :title, message: "标题不能为空"
	validates_presence_of :body, message: "内容不能为空"
	validates_presence_of :slug,message: "访问地址不能为空"

	include Metable
end