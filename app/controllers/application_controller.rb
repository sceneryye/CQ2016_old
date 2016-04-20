#encoding:utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include Breadcrumb
 

  layout "survey"

  # before_filter :authorize_user!
  before_filter :adjust_format_for_mobile
  before_filter :find_user,:find_session_id,:find_cart!
  before_filter :find_path_seo
  before_filter :menu_brands, :menu_categories


  require "pp"

 
  private 

    def menu_brands
      @menu_brands = Brand.all
    end

     def menu_categories
      @menu_categories = Category.where(disabled:'false').order('p_order DESC')
    end


    def adjust_format_for_mobile
        request.format = :mobile if params[:agent] == "mobile"
    end

    def find_session_id
       cookies[:m_id] = request.session_options[:id] unless cookies[:m_id].present?
       @m_id = cookies[:m_id]
    end

    def find_cart!
        
        if signed_in?
          @line_items = Cart.where(:member_id=>current_account.account_id)

        else
          member_ident = @m_id
          @line_items = Cart.where(:member_ident=>member_ident)
        end

        if  @line_items.size>0

          @cart_total_quantity = @line_items.inject(0){ |t,l| t+=l.quantity }.to_i || 0
         
          @cart_total = @line_items.select{|x| x.product.present? }.collect{ |x| (x.product.price*x.quantity).round }.inject(:+) || 0
        
         #@pmtable = @line_items.select { |line_item| line_item.good.is_suit? }.size == 0
        end
    end

    def find_user
      # if Rails.env == "development"
      #   return  @user = User.find_by_member_id(217)
      # end

      unless signed_in?
         nologin_times = cookies[:nologin_times] || 0
         cookies[:nologin_times] = nologin_times.to_i + 1
      end


      return  true if (params[:token].present? || params[:agent] == "mobile") && !signed_in?
      if signed_in?
        @user = current_account.user
      else
          # return (render :js=>"window.location.href='#{site_path}'") if request.xhr?
      	   # redirect_to (site_path)
      end
    end

    # find categories
    def require_top_cats
      @top_cats = Category.where(:parent_id=>0).where('sell=true or future=true or agent=true').where("cat_name not in (?)",['时装周预售','会员卡']).order("p_order asc")
    end

    def find_path_seo

      return  unless request.method == "GET"

      path  = request.env["PATH_INFO"]

      metas = MetaSeo.path_metas.where(:path=>path).select do |meta|
          if meta.params.blank?
              true
          else
              meta.params.select do |key, val|
                 reg = Regexp.new("^#{val}$")
                 params[key] =~ reg
              end.size == meta.params.size
          end
      end

      @meta_seo  = metas.first

    end

  def check_token
    if session[:authenticity_token] == params[:authenticity_token]
      session[:authenticity_token] = nil
      session.update
      return true
    end
    false
  end
end
