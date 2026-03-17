class AddOnDeleteCascadeToTenantFks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # watchlist_items → tenants
    remove_foreign_key :watchlist_items, :tenants
    add_foreign_key    :watchlist_items, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :watchlist_items, :tenants

    # user_category_interests → tenants
    remove_foreign_key :user_category_interests, :tenants
    add_foreign_key    :user_category_interests, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :user_category_interests, :tenants

    # pages → tenants
    remove_foreign_key :pages, :tenants
    add_foreign_key    :pages, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :pages, :tenants
  end
end
