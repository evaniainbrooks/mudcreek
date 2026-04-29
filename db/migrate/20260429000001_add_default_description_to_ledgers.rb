class AddDefaultDescriptionToLedgers < ActiveRecord::Migration[8.0]
  def change
    add_column :ledgers, :default_description, :string
  end
end
