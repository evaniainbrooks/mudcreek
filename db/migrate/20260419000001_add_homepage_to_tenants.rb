class AddHomepageToTenants < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :tenants, :homepage_type, :string, default: "listings", null: false
    add_column :tenants, :homepage_page_id, :bigint
    add_foreign_key :tenants, :pages, column: :homepage_page_id, validate: false
    add_index :tenants, :homepage_page_id, algorithm: :concurrently
  end
end
