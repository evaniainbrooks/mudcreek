class CreateNavbarItems < ActiveRecord::Migration[8.0]
  def change
    create_table :navbar_items do |t|
      t.references :tenant, null: false, foreign_key: true, index: false
      t.string :icon
      t.string :title, null: false
      t.string :path, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :navbar_items, [:tenant_id, :position]
  end
end
