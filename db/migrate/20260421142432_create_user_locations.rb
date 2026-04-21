class CreateUserLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :user_locations do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }
      t.references :user,     null: false, foreign_key: { on_delete: :cascade }
      t.references :location, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :user_locations, [:user_id, :location_id], unique: true
  end
end
