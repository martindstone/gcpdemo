class CreateMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :message_templates do |t|
      t.string :name
      t.text :text

      t.timestamps
    end
  end
end
