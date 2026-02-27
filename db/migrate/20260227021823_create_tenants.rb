class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :key, null: false
      t.boolean :default, null: false, default: false

      t.timestamps
    end

    add_index :tenants, :key, unique: true
    add_index :tenants, :default, unique: true, where: '"default" = true', name: "index_tenants_on_default_true"
  end
end
