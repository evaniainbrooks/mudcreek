class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :locations, [:tenant_id, :name]
  end
end
