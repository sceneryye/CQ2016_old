#encoding:utf-8
require "iconv"
require 'axlsx'
require 'csv'
require 'allinpay'
class Admin::CardsController < Admin::BaseController
      skip_before_filter :require_permission!
      skip_before_filter :verify_authenticity_token,:only=>[:batch]
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

      cards = Card.all
      package = Axlsx::Package.new
          workbook = package.workbook

            workbook.styles do |s|

          workbook.add_worksheet(:name => "ordersinfo") do |sheet|

          sheet.add_row ["卡号","面值","类型","销售状态","使用状态","卡状态","使用人手机","银行","银行卡号"]
                     

            row_count=0

            cards.each do |card| 

              nober=card.no + " "
              cardvalue=card.value
              cardtype="[#{level(card.card_type)}]" if level(card.card_type)
              salestatus=card.sale_status ? "已出售" : "未出售"
              usestatus=card.use_status ?  "已使用" : "未使用"
              cardstatus=card.status 
              usephoto = card.member_card&&card.member_card.user_tel.present? ? card.member_card.user_tel : "未登记"
              bankname = card.member_card.bank_name if !card.member_card.nil?
              cbankmenber = card.member_card.bank_card_no if !card.member_card.nil?

              sheet.add_row [nober,cardvalue,cardtype,salestatus,usestatus,cardstatus,usephoto,bankname,cbankmenber]
              row_count +=1
            end
           end
          send_data package.to_stream.read,:filename=>"card_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xlsx"
          end
    
       end


  # def export
 #     @logger ||= Logger.new("log/card.log")
  #    
   #   if params[:card][:select_all].to_i > 0
    #     @cards = Card.all
    #  else
    #    @cards = Card.find(params[:selected_cards])
     # end
    #  fields = ["卡号","面值","类型","销售状态","使用状态","卡状态","购卡人手机","用卡人手机","标签"]
  #    content =content_generate(fields,@cards)  #调用export方法
#      send_data(content, :type => 'text/csv',:filename => "card_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv")
#  end
#
#  def content_generate(fields,cards)
  #    output = CSV.generate do |csv|
 #       csv << fields
 #       cards.each do |card|
  #        content = []
     #     content.push card.no
         # content.push card.value
       #   content.push card.card_type
       #   content.push card.status
      #    content.push card_sale_status_options[card.sale_status]
      #    content.push card_use_status_options[card.use_status]
      #    content.push sold_card_status_options[card.status]
          #if card.member_card.nil?
         #     content.push ""
        #  else
       #       content.push card.member_card.buyer_tel
      #    end
     #     if card.member_card.nil?
    #          content.push ""
   #       else
  #            content.push card.member_card.user_tel
  #        end
  #        csv << content   # 将数据插入数组中
    #    end
   #   end
 # end

  def import(options={:encoding=>"GB18030:UTF-8"})
        file = params[:card][:file].tempfile
        book = Spreadsheet.open(file)
        pp "starting import ..."
        sheet = book.worksheet(0)

        @card = Card.new
    
        sheet.each_with_index do |row,i|
           
            if i >= 0
              @card = Card.new
              @card_no = Card.find_by_no(row[0].strip)
         
                   if @card_no&&@card_no.persisted?
                        @card = @card_no
                    else
                      
                        @card.no = row[0]
                    end 
                     @Card.password=row[1]
                     @Card.card_type=row[2]
                     @card.save!

             end
         end
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
