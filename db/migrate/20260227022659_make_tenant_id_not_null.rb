class MakeTenantIdNotNull < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      change_column_null :listings, :tenant_id, false
      change_column_null :users, :tenant_id, false
      change_column_null :roles, :tenant_id, false
      change_column_null :permissions, :tenant_id, false
      change_column_null :listings_categories, :tenant_id, false
      change_column_null :cart_items, :tenant_id, false
    end
  end
end
