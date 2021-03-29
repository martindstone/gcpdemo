class IncidentsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def new
  end

  def create
    i = Incident.new(params.permit(:omg_id, :omg_title, :drill_tester_email, :workspace_bugs, :gcp_bugs))
    i.save
    redirect_to incident_url(i)
  end

  def show
    @incident = Incident.find(params[:id])
  end
end
