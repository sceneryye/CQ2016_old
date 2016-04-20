class Admin::HomesController < Admin::BaseController
  def index
  	@homes = Home.paginate(:page=>params[:page],:per_page=>10).order("created_at desc")
  end

  def new
  	@home  = Home.new
  	@action_url = admin_homes_path
       @method = :post
  end

  def edit
  	@home  = Home.find(params[:id])
  	@action_url = admin_home_path(@home)
      @method = :put
  end

  def create
  	@home  = Home.new(params[:home])
  	if @home.save
  		redirect_to admin_homes_url
  	else
  		@action_url = admin_homes_path
  		render "new"
  	end
  end

  def update
  	@home  = Home.find(params[:id])
  	if @home.update_attributes(params[:home])
  		redirect_to admin_homes_url
  	else
  		@action_url = admin_home_path(@home)
  		render "edit"

  	end
  end

  def destroy
  	@home  = Home.find(params[:id])
  	@home.destroy
  	redirect_to admin_homes_path
  end


end
