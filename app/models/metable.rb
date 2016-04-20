module Metable
	def self.included(base)

		base.mattr_accessor :meta_seo_attributes

		base.has_one :meta_seo, :as=>:metable, :dependent=>:destroy
		base.accepts_nested_attributes_for :meta_seo
	end
end