class AddRentalFieldsToCartItems < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_items, :rental_start_at,    :datetime
    add_column :cart_items, :rental_end_at,      :datetime
    add_column :cart_items, :rental_price_cents, :integer
  end
end
