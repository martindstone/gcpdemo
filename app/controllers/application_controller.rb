class ApplicationController < ActionController::Base
  before_action :get_current_user

  def get_current_user
    @current_user = current_user
  end
end
