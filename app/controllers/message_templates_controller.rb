class MessageTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :get_current_user

  def index
  end

  def new
  end

  def create
    t = MessageTemplate.new(params.permit(:name, :text))
    t.save
    redirect_to message_template_url(t)
  end

  def show
    @template = MessageTemplate.find(params[:id])
  end

  def get_current_user
    @user = current_user
  end
end
