class Cart < ActiveRecord::Base
  belongs_to :user, foreign_key: :user_id
  has_many :cart_items, foreign_key: :cart_id, dependent: :destroy
end
