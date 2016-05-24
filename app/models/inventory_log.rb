class InventoryLog < ActiveRecord::Base

  belongs_to :product, :foreign_key=>"product_id"
  # belongs_to :order_item, :foreign_key=>"order_items_id"
  belongs_to :order,:foreign_key=>"order_id"

  
end