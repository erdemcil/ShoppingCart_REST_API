require "bundler/setup"
require "sinatra"
require "warden"
require "pry"
# require "rack/csrf"
require "sinatra/activerecord"
require "sinatra/reloader" if development?

set :database, {adapter: "sqlite3", database: "shoppingCart.sqlite3"}

Dir.glob(File.join("helpers", "**", "*.rb")).each do |helper|
  require_relative helper
end

Dir["./models/*.rb"].each {|file| require file }

use Rack::Session::Cookie, :secret => "zebramo"
# use Rack::Csrf, :raise => true
enable :sessions

use Warden::Manager do |m|
  m.default_strategies :password
  m.failure_app = FailureApp.new
end

Warden::Manager.serialize_into_session do |user|
  puts '[INFO] serialize into session'
  user.id
end

Warden::Manager.serialize_from_session do |id|
  puts '[INFO] serialize from session'
  User.find_by(id)
end

Warden::Strategies.add(:password) do
  def valid?
    puts '[INFO] password strategy valid?'

    params['username'] || params['password']
  end
  def authenticate!
  puts '[INFO] password strategy authenticate'
  u = User.authenticate(params['username'], params['password'])
  u.nil? ? fail!('Could not login in') : success!(u)
  end
end

class FailureApp
  def call(env)
    uri = env['REQUEST_URI']
    puts "failure #{env['REQUEST_METHOD']} #{uri}"
  end
end


post '/auth/login' do
  if env['warden'].authenticate

    env['warden'].set_user(@user)
    {message: "Authentication Success"}.to_json
  else
    {message: "Authentication Failure"}.to_json
  end
end

get '/auth/logout' do
  env['warden'].logout
  {message: "Session Ended"}.to_json
end

get "/" do
  erb :index
end

get "/users" do
  content_type 'application/json'

	User.all.to_json
end

post '/users' do

  user = User.new
	user.username = params[:username]
	user.email = params[:email]
	user.password = params[:password]
	user.save
end

get '/users/:id' do

	content_type 'application/json'

	user = User.find(params[:id])
	if user == nil
		return status 404
	end
	user.to_json
end

get '/users/:uid/carts' do

  content_type 'application/json'

  response = []
  user = User.find_by(id: params[:uid])

  if user.carts == nil
		return status 404
	end

  response = user.as_json(only: [:id, :username],include: { carts: {include: :cart_items}})
  response.to_json
end

post '/users/:id/carts' do

  cart = Cart.new
  cart.user_id = params[:id]
  cart.save
end


get "/products" do
  content_type 'application/json'

	Product.all.to_json

end

post '/products' do

  product = Product.new
	product.name = params[:name]
	product.price = params[:price]
	product.save
end

get '/products/:id' do

	content_type 'application/json'

	product = Product.find(params[:id])
	if product == nil
		return status 404
	end
	product.to_json
end

get '/carts/:cid' do

	content_type 'application/json'

  cart = Cart.find_by(id: params[:cid])

  response = cart.as_json(include: { cart_items: {only: [:id, :quantity], include: :product}})
  response.to_json
end

post '/carts/:id/products' do

  params[:quantity] ||= 1

  cart_item = CartItem.new
  cart_item.cart_id = params[:id]
  cart_item.product_id = params[:product_id]
  cart_item.quantity = params[:quantity].to_i
  cart_item.save
end

delete '/carts/:cid/products/:pid' do

	cart_item = CartItem.find_by(cart_id: params[:cid], product_id: params[:pid])
  cart_item.destroy
end

put '/carts/:id/products/:pid' do

  cart_item = CartItem.find_by(cart_id: params[:pid])
  cart_item.quantity = params[:quantity]
  cart_item.save
end

put '/carts/:cid/clean' do

  if CartItem.where(cart_id: params[:cid]).delete_all
    {message: "Cart cleaned successfully"}.to_json
  end
end
