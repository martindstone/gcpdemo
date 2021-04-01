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
    i = current_user.incidents.new(params.permit(:omg_id, :omg_title, :drill_tester_email, :workspace_bugs, :gcp_bugs, :color, :description, :impacted_customers))
    i.save
    redirect_to incident_url(i)
  end

  def edit
    @incident = Incident.find(params[:id])
  end

  def update
    i = Incident.find(params[:id])
    fields = [:omg_title, :drill_tester_email, :workspace_bugs, :gcp_bugs, :color, :description, :impacted_customers]
    for field in fields
      if params[field] != i[field]
        i.activities.create(description: "Changed #{field.to_s.humanize.titleize} from '#{i[field]}' to '#{params[field]}'")
      end
    end
    i.update(params.permit(:omg_title, :drill_tester_email, :workspace_bugs, :gcp_bugs, :color, :description, :impacted_customers))
    i.save
    redirect_to incident_url(i), notice: "Incident updated"
  end

  def show
    @incident = Incident.find(params[:id])
    if @incident.pd_incident_id.nil?
      @services = PdClient.fetch(@user.api_key, 'services')
    else
      @pd_incident = PdClient.get(@user.api_key, "incidents/#{@incident.pd_incident_id}", {include: ['responders']})
      @response_plays = PdClient.fetch(@user.api_key, 'response_plays', {filter_for_manual_run: true}, {'From': @user.email})
      @subscribers = PdClient.get(@user.api_key, "incidents/#{@incident.pd_incident_id}/status_updates/subscribers")['subscribers']
      @users = PdClient.fetch(@user.api_key, 'users')
      @eps = PdClient.fetch(@user.api_key, 'escalation_policies')
      @teams = PdClient.fetch(@user.api_key, 'teams')
    end
  end

  def destroy
    i = Incident.find(params[:id])
    if i.state == "closed"
      i.destroy
      redirect_to incidents_url, notice: "Baleeted"
    else
      i.state = "closed"
      i.save
      redirect_to incidents_url, notice: "Closed"
    end
  end

  def create_pd_incident
    i = Incident.find(params[:id])
    if i.nil?
      redirect_to root_url, alert: 'oops, no incident'
    end
    if not i.pd_incident_id.nil?
      redirect_to incident_url(i), alert: 'oops, already has'
    end
    details = "OMG ID: #{i.omg_id}\n" +
      "OMG Title: #{i.omg_title}\n" +
      "Drill Tester Email: #{i.drill_tester_email}\n" +
      "Workspace Bugs: #{i.workspace_bugs}\n" +
      "GCP Bugs: #{i.gcp_bugs}"
    body = {
      incident: {
        type: "incident",
        title: i.omg_title,
        service: {
          type: "service_reference",
          id: params[:service_id]
        },
        body: {
          type: "incident_body",
          details: details
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

  def add_responders
    i = Incident.find(params[:id])
    responders = []
    user_ids = params[:user_ids] || []
    ep_ids = params[:ep_ids] || []
    for user_id in user_ids
      responders << {
        responder_request_target: {
          type: "user_reference",
          id: user_id
        }
      }
    end
    for ep_id in ep_ids
      responders << {
        responder_request_target: {
          type: "escalation_policy_reference",
          id: ep_id
        }
      }
    end
    if responders.count == 0
      redirect_to incident_url(i), notice: "Nothing to do"
      return
    end

    pd_user = PdClient.get(@user.api_key, 'users', {query: @user.email})['users'][0]
    body = {
      requester_id: pd_user['id'],
      message: "Please help with '#{i.omg_title}'",
      responder_request_targets: responders
    }
    rq = PdClient.post(@user.api_key, @user.email, "incidents/#{i.pd_incident_id}/responder_requests", JSON.generate(body))
    things_added = []
    if user_ids.count > 0
      things_added << "users #{user_ids.to_sentence}"
    end
    if ep_ids.count > 0
      things_added << "escalation policies #{ep_ids.to_sentence}"
    end
    i.activities.create(description: "Added #{things_added.to_sentence} as responders")

    redirect_to incident_url(i), notice: "Responders added"
  end

  def add_subscribers
    i = Incident.find(params[:id])
    subscribers = []
    user_ids = params[:user_ids] || []
    team_ids = params[:team_ids] || []
    for user_id in user_ids
      subscribers << {
        subscriber_id: user_id,
        subscriber_type: "user"
      }
    end
    for team_id in team_ids
      subscribers << {
        subscriber_id: team_id,
        subscriber_type: "team"
      }
    end
    if subscribers.count == 0
      redirect_to incident_url(i), notice: "Nothing to do"
      return
    end

    body = {
      subscribers: subscribers
    }
    rq = PdClient.post(@user.api_key, @user.email, "incidents/#{i.pd_incident_id}/status_updates/subscribers", JSON.generate(body))
    things_added = []
    if user_ids.count > 0
      things_added << "users #{user_ids.to_sentence}"
    end
    if team_ids.count > 0
      things_added << "teams #{team_ids.to_sentence}"
    end
    i.activities.create(description: "Added #{things_added.to_sentence} as subscribers")
    redirect_to incident_url(i), notice: "Subscribers added"
  end

  def message_preview_raw
    i = Incident.find(params[:id])
    t = MessageTemplate.find(params[:template_id])
    e = ERB.new(t.text)
    pdincident = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}", {include: ['metadata']})['incident']
    pdi = JSON.parse(pdincident.to_json, object_class: OpenStruct)
    log_entries = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}/log_entries")['log_entries']
    les = JSON.parse(log_entries.to_json, object_class: OpenStruct)
    @incident = i
    @html_message = e.result(binding)
    render inline: "<%= raw @html_message %>"
  end

  def message_preview
    @incident = Incident.find(params[:id])
    @template = MessageTemplate.find(params[:template_id])
    i = @incident
    pdincident = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}", {include: ['metadata']})['incident']
    pdi = JSON.parse(pdincident.to_json, object_class: OpenStruct)
    log_entries = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}/log_entries")['log_entries']
    les = JSON.parse(log_entries.to_json, object_class: OpenStruct)
    se = ERB.new(@template.short_text)
    @short_message = se.result(binding)
    render "preview"
  end

  def message_send
    i = Incident.find(params[:id])
    t = MessageTemplate.find(params[:template_id])
    e = ERB.new(t.text)
    se = ERB.new(t.short_text)
    pdincident = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}", {include: ['metadata']})['incident']
    pdi = JSON.parse(pdincident.to_json, object_class: OpenStruct)
    log_entries = PdClient.get(@user.api_key, "incidents/#{i.pd_incident_id}/log_entries")['log_entries']
    les = JSON.parse(log_entries.to_json, object_class: OpenStruct)
    html_message = e.result(binding)
    plain_message = se.result(binding)
    subject = "Status update for incident \"#{i.omg_title}\""
    body = {
      content_type: "text/html",
      contact_method_types: ["email"],
      subject: subject,
      message: html_message
    }
    r = PdClient.post(@user.api_key, @user.email, "incidents/#{i.pd_incident_id}/status_updates", JSON.generate(body))
    body = {
      content_type: "text/plain",
      contact_method_types: ["sms", "push_notification"],
      message: plain_message
    }
    r = PdClient.post(@user.api_key, @user.email, "incidents/#{i.pd_incident_id}/status_updates", JSON.generate(body))
    i.activities.create(description: "Sent status update")
    redirect_to incident_url(i), notice: "Status update sent"
  end

  def response_play
    i = Incident.find(params[:id])
    body = {
      incident: {
        id: i.pd_incident_id,
        type: "incident_reference"
      }
    }
    r = PdClient.post(@user.api_key, @user.email, "response_plays/#{params[:response_play_id]}/run", JSON.generate(body))
    redirect_to incident_url(i), notice: "Running response play"
  end

  def get_current_user
    @user = current_user
  end
end
