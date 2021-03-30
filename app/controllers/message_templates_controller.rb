class MessageTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :get_current_user

  def index
  end

  def new
  end

  def create
    t = MessageTemplate.new(params.permit(:name, :text, :short_text))
    t.save
    redirect_to message_template_url(t)
  end

  def show
    @template = MessageTemplate.find(params[:id])
  end

  def edit
    @message_template = MessageTemplate.find(params[:id])
  end

  def update
    t = MessageTemplate.find(params[:id])
    t.update(params.permit(:name, :text, :short_text))
    redirect_to message_template_url(t)
  end

  def destroy
    t = MessageTemplate.find(params[:id])
    t.destroy
    redirect_to message_templates_url, notice: "Baleeted"
  end

  def get_current_user
    @user = current_user
  end
end
