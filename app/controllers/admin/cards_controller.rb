#encoding:utf-8
require 'csv'
require 'allinpay'
class Admin::CardsController < Admin::BaseController
  include Admin::CardsHelper
  # GET /admin/cards
  # GET /admin/cards.json
  include Allinpay

  before_filter :require_permission!

  before_action :set_card, only: [:show,:allinpay,:edit, :update, :destroy,:buy,:use,:edit_user]

  def trading_log
    @log = CardTradingLog.order("id ASC")
    if params[:card_no]
      @log =@log.where(card_no: params[:card_no])
    end
    @log = @log.paginate(:page=>params[:page],:per_page=>20)
  end
  
  def allinpay () end

  def index
    @labels = Label.all

    sale_status = params[:sold] == "0" ? false : true
    key = params[:search][:key] if params[:search]

    @cards = Card.order("id ASC")

    if params[:sold].present?
        @cards = @cards.where(:sale_status=>sale_status)
    end

    if key.present?
        @cards = @cards.where("no like :key",:key=>"%#{key}%")
    end


    @cards = @cards.paginate(:page=>params[:page],:per_page=>20)
    @cards_total = Card.count

  end

  def show ()  end

  def new 
      @card = Card.new
  end

  def edit () end

  def create
    @card = Card.new(params[:card])

    respond_to do |format|
      if @card.save
        format.html { redirect_to @card, notice: 'Card was successfully created.' }
        format.json { render json: @card, status: :created, location: @card }
      else
        format.html { render action: "new" }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @card.update_attributes(params[:card])

        message = params[:card].collect  do |key,value|
            I18n.t("card.#{key}") + "=" + value
        end.join(",")

        CardLog.create(:member_id=>current_admin.account_id,
                                                :card_id=>@card.id,
                                                :message=>"更新卡信息,#{message}")

        format.html { redirect_to admin_cards_url, notice: 'Card was successfully updated.' }
        format.json { head :no_content }
        format.js
      
      else
        format.html { render action: "edit" }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @card.destroy

    respond_to do |format|
      format.html { redirect_to cards_url }
      format.json { head :no_content }
    end
  end

  def buy () end

  def use () end

  def edit_user 
      @member_card = @card.member_card
      @buyer =  @member_card.buyer
  end
  
  def edit_pay
      @card = Card.find(params[:id])
      @user_card = @member_card = @card.member_card
  end

  def logs
      @card = Card.find(params[:id])
      @logs = @card.card_logs
  end

  def tag

      if params[:cards] == "all"
          @cards = Card.all
      else
          @cards = Card.find(params[:cards])
      end
      @cards.each do |card|
         Labelable.where(:label_id=>params[:label],
                         :labelable_id=>card.id,
                         :labelable_type=>"Card").first_or_create if card
      end

      render :text=>"ok"
  end

  def untag
      @card = Card.find(params[:id])
      @card.labelables.where(:label_id=>params[:label]).delete_all
      render "untag"
  end

  def cancel_order
     @card = Card.find(params[:id])
     @card.update_attribute :sale_status,false
     @member_card = @card.member_card
     CardLog.create(:member_id=>current_admin.account_id,
                    :card_id=>@card.id,
                    :message=>"取消卡订单,购买者=#{@member_card.buyer.login_name}")
     @member_card.destroy
     redirect_to admin_cards_url
  end

  def export
      @logger ||= Logger.new("log/card.log")
      
      if params[:card][:select_all].to_i > 0
         @cards = Card.all
      else
        @cards = Card.find(params[:selected_cards])
      end
      fields = ["卡号","面值","类型","销售状态","使用状态","卡状态","购卡人手机","用卡人手机","标签"]
      content =content_generate(fields,@cards)  #调用export方法
      send_data(content, :type => 'text/csv',:filename => "card_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv")
  end

  def content_generate(fields,cards)
      output = CSV.generate do |csv|
        csv << fields
        cards.each do |card|
          content = []
          content.push card.no
          content.push card.value
          content.push card.card_type
          content.push card.status
          content.push card_sale_status_options[card.sale_status]
          content.push card_use_status_options[card.use_status]
          content.push sold_card_status_options[card.status]
          if card.member_card.nil?
              content.push ""
          else
              content.push card.member_card.buyer_tel
          end
          if card.member_card.nil?
              content.push ""
          else
              content.push card.member_card.user_tel
          end
          csv << content   # 将数据插入数组中
        end
      end
  end

  def import(options={:encoding=>"GB18030:UTF-8"})

        return redirect_to(admin_cards_url) unless params[:card]&&params[:card][:file] 

        file = params[:card][:file].tempfile
        csv_rows = CSV.read(file,options)
        @logger ||= Logger.new("log/card.log")
        @cols = CvsColumn.new
        first_row = 0
        @cols.parseModel(csv_rows[first_row])
        csv_rows.shift
        errors = {}
        begin
            Card.transaction do
                csv_rows.each_with_index do |row,idx|
                  index = @cols.index("卡号")
                  card_no = row[index]
                  @new_card = Card.find_by_no(row[index])
                  if !@new_card.nil? && @new_card.persisted?
                    @logger.error("[error]card no exist: ")
                    errors[idx+2] = "导入失败,卡号:#{card_no}已经存在."
                    next
                    # render :text=>"【异常】卡号已经存在"
                    # return
                  else
                    @card = Card.new
                  end
                  @card.no = row[index]
                  index = @cols.index("面值")
                  @card.value = row[index]
                  t_index = @cols.index("类型")
                  @card.card_type = row[t_index]
                  @card.status = "正常"
                  @card.sale_status = 0
                  @card.use_status = 0

                  if %(A B).include?(row[t_index])
                      if row[t_index] == "B"
                        index = @cols.index("激活码")
                        @card.password = row[index]
                        if row[index].blank?
                          errors[idx+2] = "导入失败,卡[#{card_no}]密码不能为空."
                          next
                        end
                      end
                  else
                        @logger.error("[error]card_type  can not be #{row[t_index]}")
                        errors[idx+2] = "导入失败,卡[#{card_no}]类型只能是A或者B,不能为其他值."
                        next
                  end
                  @card.save!
                  errors[idx+2] = "导入成功,卡号[#{card_no}]"
                end
            end
        rescue Exception => e
            @logger.error("[error]import card cvs error: "+e.to_s)
            errors[-9999] = "导入失败，请检查导入文件格式."
            # raise e
        end

        flash[:notice] = errors unless errors.empty?
        redirect_to admin_cards_path
  end

  def active
    order_id = params[:order_id]
    card_id = params[:card_id]
    type = params[:type]
    res_data = ActiveSupport::JSON.decode card_active(order_id, card_id, type)
    save_log res_data,card_id,'active'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def topup
    #data = params.permit(:order_id, :card_id, :prdt_no, :amount, :top_up_way, :opr_id, :desn)
    order_id = params[:order_id]
    card_id = params[:card_id]
    prdt_no = params[:prdt_no]
    amount = params[:amount]
    top_up_way = params[:top_up_way]
    opr_id = params[:opr_id]
    desn = params[:desn]
    res_data = ActiveSupport::JSON.decode topup_single_card(order_id, card_id, prdt_no, amount, top_up_way, opr_id, desn)
    save_log res_data,card_id,'topup'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def pay_with_pwd
    order_id = params[:order_id]
    mer_order_id = params[:mer_order_id]
    payment_id = params[:payment_id]
    amount = params[:amount]
    card_id = params[:card_id]
    password = params[:password]
    res_data = ActiveSupport::JSON.decode pay_with_password(order_id,  mer_order_id, payment_id, amount, card_id, password)
    save_log res_data,card_id,'pay_with_pwd'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def reset_password
    order_id = params[:order_id]
    card_id = params[:card_id]
    password = params[:password]
    res_data = ActiveSupport::JSON.decode card_reset_password(order_id, card_id, password)
    save_log res_data,card_id,'reset_password'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def freeze
    order_id = params[:order_id]
    card_id = params[:card_id]
    prdt_id = params[:prdt_id]
    reason = params[:reason]
    res_data = ActiveSupport::JSON.decode card_freeze(order_id, card_id, prdt_id, reason)
    save_log res_data,card_id,'freeze'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def unfreeze
    order_id = params[:order_id]
    card_id = params[:card_id]
    prdt_id = params[:prdt_id]
    reason = params[:reason]
    res_data = ActiveSupport::JSON.decode card_unfreeze(order_id, card_id, prdt_id, reason)
    save_log res_data,card_id,'unfreeze'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def report_loss
    order_id = params[:order_id]
    card_id = params[:card_id]
    id_type = params[:id_type]
    id_no = params[:id_no]
    reason = params[:reason]
    res_data = ActiveSupport::JSON.decode card_report_loss(order_id, card_id, id_no, id_type, reason)
    save_log res_data,card_id,'report_loss'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def cancel_loss
    order_id = params[:order_id]
    card_id = params[:card_id]
    id_type = params[:id_type]
    id_no = params[:id_no]
    reason = params[:reason]
    res_data = ActiveSupport::JSON.decode card_cancel_loss(order_id, card_id, id_no, id_type, reason)
    save_log res_data,card_id,'cancel_loss'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def get_info
    card_id = params[:card_id]
    password = params[:password]
    res_data = ActiveSupport::JSON.decode card_get_info(card_id, password)
    save_log res_data,card_id,'get_info'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def get_trade_log
    begin_date = params[:begin_date]
    end_date = params[:end_date]
    card_id = params[:card_id]
    password = params[:password]
    page_no = params[:page_no]
    page_size = params[:page_size]
    # return render json: {data: {error_message: '不能查询90天之前的记录！'}} if Time.parse(begin_date) < (Time.now - 3600 * 24 * 90)
    res_data = ActiveSupport::JSON.decode card_get_trade_log(begin_date, end_date, card_id, password, page_no, page_size)
    save_log res_data,card_id,'get_trade_log'
    Rails.logger.info res_data
    render json: {data: res_data}
  end

  def pay_to_client
    data = params[:pay_to_client]
    res_data = Hash.from_xml pay_for_another data
    render json: {data: res_data}
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def save_log (res_data,card_no,from='')

    card_id = Card.find_by_no(card_no)[:id]

    @cards_log ||= Logger.new('log/cards.log')

    @cards_log.info("[admin][#{Time.now}]#{res_data}")

    @card_log = CardLog.create(:member_id=>1,
                  :card_no=>card_no,
                  :card_id=>card_id,
                  :message=>"#{res_data.to_json}")
  end

end
