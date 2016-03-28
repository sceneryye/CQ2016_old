#encoding:utf-8
class Admin::DiscountCodesController < Admin::BaseController
  before_filter :require_permission!

  def show

  end
  def index
    @codes = Ecstore::DiscountCode.paginate(:page => params[:page], :per_page => 20).order("member_id DESC,status DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @logs }
    end
  end

  def new
    if params[:discount_card]
      (1..1000).each do |i|
        @discount_code=Ecstore::DiscountCode.new do |code|
          code.code = '2015113010' +random_string(2).to_s + '0000'[0, 4-i.to_s.length] + i.to_s
          code.password = random_string(6).to_s
          code.value  = 1000
          code.card_name = '心意卡'
          code.coupon_id = 2
        end
         @discount_code.save!
      end
    end
    redirect_to admin_discount_codes_url

  end

  def create
  end

  def edit
   @code = Ecstore::DiscountCode.find_by_code(params[:id])
   @doctor = Ecstore::User.where("member_lv_id=2")
  end

  def update
    @code = Ecstore::DiscountCode.find_by_code(params[:id])

    respond_to do |format|
      if @code.update_attributes(params[:code])
        format.html { redirect_to admin_discount_codes_url, notice: 'Discount_code was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @codes.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def random_string(len)
      #chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      chars = ("0".."9").to_a
      str = ""
      1.upto(len) { |i| str << chars[rand(chars.size-1)] }
      return str
    end


end
