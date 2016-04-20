# encoding:utf-8
require 'ya2yaml'
require 'sms'

module Admin
    class MembersController < Admin::BaseController

      def index
        @total_member = Member.count()
        
        @members = Member.paginate(:page => params[:page], :per_page => 20).order("member_id DESC")
        

        @column_data = YAML.load(File.open(Rails.root.to_s+"/config/columns/member.yml"))

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @members }
        end
      end

      def show
      end

      def edit
        @member = Member.find(params[:id])
      end

      def updateInfo
        @member = Member.find(params[:id])
        @member.update_attributes(params[:member])
        
        # @member.mobile = params[:member][:mobile]
        # @member.email = params[:member][:email]
        # @member.member_lv_id = params[:member][:member_lv_id]
        if @member.advance != params[:member][:advance].to_i
          @adv_log ||= Logger.new('log/adv.log')
          @adv_log.info("member id: "+@member.member_id.to_s+"--advance:"+@member.advance.to_s+"=>"+params[:member][:advance])
          # @member.advance = params[:member][:advance]
        end
        # @member.save
        redirect_to admin_members_path
      end

      def info
        @member = Member.find(params[:id])
      end

      def send_sms
          if  params[:send_all] == "1"
              tels =  Member.all.select { |u| u.mobile.present?&&(/^[1-9][0-9]{10}$/ =~ u.mobile) }.collect{|x| x.mobile}
          else
              tels = params[:tels]
          end

          text = params[:member][:text]


          if text.blank?
              render :js=>"alert('短信内容不能为空');"
              return
          end

          @sms_log ||= Logger.new('log/sms.log')
          begin
             while tels.size > 20 do
                 sends = tels.slice!(0,20).join(";")
                 if Sms.send(sends,text)
                    @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{sends}]短信群发:#{text}")
                 end
             end
             if tels.size > 0
                sends = tels.slice!(0,20).join(";")
                if Sms.send(sends,text)
                  @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{sends}]短信群发:#{text}")
                end
             end
          rescue

          end

        respond_to do |format|
          format.js
        end

      end


      def send_sms2
        tels = params[:member][:mobiles]
        text = params[:member][:text]

        if tels.blank?
              render :js=>"alert('请填写手机号码');"
              return
        end


        if text.blank?
              render :js=>"alert('短信内容不能为空');"
              return
        end
        @sms_log ||= Logger.new('log/sms.log')

        begin
          tels = tels.split(";").select{|x| x.present?&&(/^[1-9][0-9]{10}$/ =~ x)}.join(";")
          if Sms.send(tels,text)
              @sms_log.info("[#{current_admin.login_name}][#{Time.now}][#{tels}]短信群发:#{text}")
          end
        rescue Exception => e
              @sms_log.info("[#{current_admin.login_name}][#{Time.now}]错误:#{e}")
        end

        respond_to do |format|
          format.js
        end

      end

      def columns
        
      end

      def export
        fields =  params[:fields]
        if params[:member][:select_all].to_i > 0
           members = Member.all  #找出所有数据
        else
           members = Member.find(:all,:conditions => ["member_id in (?)",params[:ids]])
        end
        content = Member.export(fields,members)  #调用export方法
        send_data(content, :type => 'text/csv',:filename => "member_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv")
      end

      def column_reload
         begin
            @column_data_member = YAML.load(File.open(Rails.root.to_s+"/config/columns/member.yml"))
            @column_data_member[params[:column_id]][2] = params[:col_stat]
            @yaml = @column_data_member
            File.open(Rails.root.to_s+"/config/columns/member.yml", 'w'){|f| 
              f.puts @column_data_member.ya2yaml
            }
         rescue => err 
           logger = Logger.new(Rails.root.to_s + '/log/err.log')  
           logger.error err  
           logger.close       
         end
         # @result = true
         respond_to do |format|
            format.json { render json: {success: true} }
         end
      end

      def new
      end

    end
    
end
