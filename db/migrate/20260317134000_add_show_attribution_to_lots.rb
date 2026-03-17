class AddShowAttributionToLots < ActiveRecord::Migration[8.1]
  def change
    add_column :lots, :show_attribution, :boolean, default: false, null: false
  end
end
