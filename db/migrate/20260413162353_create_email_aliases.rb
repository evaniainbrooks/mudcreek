class CreateEmailAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :email_aliases do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :external_id, null: false
      t.string :alias, null: false
      t.string :forward, null: false
      t.timestamps
    end

    add_index :email_aliases, [ :tenant_id, :external_id ], unique: true
  end
end
