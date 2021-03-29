class CreateIncidents < ActiveRecord::Migration[6.1]
  def change
    create_table :incidents do |t|
      t.string :omg_id
      t.string :omg_title
      t.datetime :omg_start
      t.string :drill_tester_email
      t.string :workspace_bugs
      t.string :gcp_bugs
      t.string :impacted_services
      t.text :workarounds

      t.timestamps
    end
  end
end
