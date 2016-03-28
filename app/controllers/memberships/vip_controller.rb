class Memberships::VipController < ApplicationController
  # layout 'memberships'
  layout 'standard'
  
  before_filter :find_user
  # skip_before_filter :authorize_user!
  
  def index
  	@return_url='/'
	  if params[:return_url]
	  	@return_url=params[:return_url]
	  end
  end
  
end