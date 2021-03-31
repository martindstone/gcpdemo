class AddStateToIncident < ActiveRecord::Migration[6.1]
  def change
    add_column :incidents, :state, :string
  end
end
