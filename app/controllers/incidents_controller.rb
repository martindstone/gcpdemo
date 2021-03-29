class IncidentsController < ApplicationController
  before_action :authenticate_user!
  before_action :get_current_user

  def index
    @incidents = current_user.incidents
  end

  def new
  end

  def create
    i = current_user.incidents.new(params.permit(:omg_id, :omg_title, :drill_tester_email, :workspace_bugs, :gcp_bugs))
    i.save
    redirect_to incident_url(i)
  end

  def show
    @incident = Incident.find(params[:id])
  end

  def get_current_user
    @user = current_user
  end
end
