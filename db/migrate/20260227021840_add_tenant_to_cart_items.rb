class AddTenantToCartItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { add_reference :cart_items, :tenant, null: true, foreign_key: true }
  end
end
