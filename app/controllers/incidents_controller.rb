include PdClient

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
    @services = PdClient.fetch(current_user.api_key, 'services')
  end

  def create_pd_incident
    i = Incident.find(params[:id])
    if i.nil?
      redirect_to root_url, alert: 'oops, no incident'
    end
    if not i.pd_incident_id.nil?
      redirect_to incident_url(i), alert: 'oops, already has'
    end
    body = {
      incident: {
        type: "incident",
        title: i.omg_title,
        service: {
          type: "service_reference",
          id: params[:service_id]
        }
      }
    }
    pd_incident = PdClient.post(@user.api_key, @user.email, 'incidents', JSON.generate(body))
    puts pd_incident
    i.pd_incident_id = pd_incident['incident']['id']
    i.pd_incident_url = pd_incident['incident']['html_url']
    i.save
    i.activities.create(description: "Created PagerDuty incident #{i.pd_incident_id}")
    redirect_to incident_url(i)
  end

  def get_current_user
    @user = current_user
  end
end
