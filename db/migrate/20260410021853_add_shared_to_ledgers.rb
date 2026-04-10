class AddSharedToLedgers < ActiveRecord::Migration[8.1]
  def change
    add_column :ledgers, :shared, :boolean, default: true, null: false
  end
end
