class User < ActiveRecord::Base
  has_many :carts, foreign_key: :user_id, dependent: :destroy
  has_many :cart_items, through: :carts
  def self.authenticate(username, password)
    user = self.find_by(username: username)
    user if user && password == user.password
  end
end
