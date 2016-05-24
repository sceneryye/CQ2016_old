class Admin::InventoryLogsController < Admin::BaseController
  before_filter :require_permission!
  def index
    @inventory_logs = InventoryLog.paginate(:page => params[:page], :per_page => 20).order("created_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @inventory_logs }
    end
  end

  def new
    @inventory_log = InventoryLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @inventory_log }
    end
  end

  def edit
    @inventory_log = InventoryLog.find(params[:id])
  end

  def create
    @inventory_log = InventoryLog.new(inventory_log_params)
    
    respond_to do |format|
      if @inventory_log.save
        format.html { redirect_to admin_inventory_logs_path, notice: 'Inventory Log was successfully created.' }
        format.json { render json: @inventory_log, status: :created, location: @inventory_log }
      else
        format.html { render action: "new" }
        format.json { render json: @InventoryLog.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @inventory_log = InventoryLog.find(params[:id])

    respond_to do |format|
      if @InventoryLog.update_attributes(inventory_log_params)
        format.html { redirect_to admin_inventory_logs_url, notice: 'Page was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @InventoryLog.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @inventory_log = InventoryLog.find(params[:id])
    @InventoryLog.destroy

    respond_to do |format|
      format.html { redirect_to admin_inventory_logs_url }
      format.json { head :no_content }
      format.js
    end
  end

 

  private
  def inventory_log_params
      params.require(:inventory_log).permit(:product_id,:quantity,:in_out)
  end
end
