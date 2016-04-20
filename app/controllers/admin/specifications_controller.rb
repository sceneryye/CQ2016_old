class Admin::SpecificationsController < Admin::BaseController

	def index
		@specs =  Spec.paginate(:per_page=>20,:page=>params[:page]).order("p_order desc")
	end

	def new
		@spec  = Spec.new

		@action_url =  admin_specifications_path
		@method = :post
	end

	def show
		@spec  = Spec.find(params[:id])
	end

	def edit
		@spec  = Spec.includes(:spec_values).find(params[:id])


		@action_url =  admin_specification_path(@spec)
		@method = :put
	end

	def create
		@spec  = Spec.new params[:spec]
		if @spec.save
			redirect_to admin_specifications_url
		else
			render :new
		end
	end

	def update
		@spec  = Spec.find(params[:id])
		if @spec.update_attributes(params[:spec])
			redirect_to admin_specifications_url
		else
			render :edit
		end
	end

	def destroy
		@spec  = Spec.find(params[:id])
		@spec.destroy
		redirect_to admin_specifications_url
	end
end
