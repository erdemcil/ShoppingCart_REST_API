class Product < ActiveRecord::Base
  has_many :cart_items, foreign_key: :product_id, dependent: :destroy
  has_many :carts, through: :cart_items, dependent: :destroy
end
