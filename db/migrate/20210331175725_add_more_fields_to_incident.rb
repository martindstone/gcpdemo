class AddMoreFieldsToIncident < ActiveRecord::Migration[6.1]
  def change
    add_column :incidents, :color, :string
    add_column :incidents, :description, :text
    add_column :incidents, :impacted_customers, :text
  end
end
