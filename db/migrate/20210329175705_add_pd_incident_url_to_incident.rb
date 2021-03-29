class AddPdIncidentUrlToIncident < ActiveRecord::Migration[6.1]
  def change
    add_column :incidents, :pd_incident_url, :string
  end
end
