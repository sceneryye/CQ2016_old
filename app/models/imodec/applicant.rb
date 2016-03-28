#encoding:utf-8
class Imodec::Applicant < ActiveRecord::Base
  attr_accessor :age, :email, :mobile, :name, :sex,:event_id

  validates_presence_of :name,:message=>"请填写姓名"
  validates_presence_of :age,:message=>"请填写年龄"
  validates :age,:numericality => { :only_integer => true,:message=>"年龄必须是数字" },:if=>Proc.new{ |c| c.age.present? }

  validates :email,:presence=>{:presence=>true,:message=>"请填写邮箱"}
  validates :email,:format=>{:with=>/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i,:message=>"邮箱格式不正确"},
					    :if=>Proc.new{ |c| c.email.present? }

  validates :mobile,:presence=>{:presence=>true,:message=>"请填写电话"}
  validates :mobile,:format=>{:with=>/^\d{11}$/,:message=>"手机号码必须是11位数字"},
					    :if=>Proc.new{ |c| c.mobile.present? }

  belongs_to :event
  
end