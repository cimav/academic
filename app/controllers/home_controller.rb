class HomeController < ApplicationController
  before_filter :auth_required
  def index
    @screen = "index"
    @staff  = Staff.find(session[:user_id])
  end
end
