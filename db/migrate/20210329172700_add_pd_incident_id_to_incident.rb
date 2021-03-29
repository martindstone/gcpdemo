class AddPdIncidentIdToIncident < ActiveRecord::Migration[6.1]
  def change
    add_column :incidents, :pd_incident_id, :string
  end
end
