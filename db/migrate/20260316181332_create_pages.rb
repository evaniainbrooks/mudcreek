class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string  :title,          null: false
      t.string  :slug,           null: false
      t.boolean :published,      null: false, default: false
      t.boolean :show_in_nav,    null: false, default: false
      t.boolean :show_in_footer, null: false, default: false
      t.integer :position,       null: false, default: 0
      t.timestamps
    end
    add_index :pages, [:tenant_id, :slug], unique: true
  end
end
