class CartItem < ActiveRecord::Base
  belongs_to :product, foreign_key: :product_id
  belongs_to :cart, foreign_key: :cart_id

end
