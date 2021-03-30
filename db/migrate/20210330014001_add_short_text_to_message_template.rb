class AddShortTextToMessageTemplate < ActiveRecord::Migration[6.1]
  def change
    add_column :message_templates, :short_text, :string
  end
end
