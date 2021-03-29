class CreateActivities < ActiveRecord::Migration[6.1]
  def change
    create_table :activities do |t|
      t.references :incident, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
