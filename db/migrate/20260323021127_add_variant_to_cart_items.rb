class AddVariantToCartItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { add_reference :cart_items, :variant, foreign_key: { to_table: :listings_variants }, null: true }

    # Remove old unique index that didn't account for variants
    remove_index :cart_items, name: "index_cart_items_unique_user_listing"
    remove_index :cart_items, name: "index_cart_items_unique_guest_listing"

    # New unique indexes that include variant_id
    safety_assured do
      add_index :cart_items, [:user_id, :listing_id, :variant_id],
        name: "index_cart_items_unique_user_listing_variant",
        unique: true,
        where: "((user_id IS NOT NULL) AND (rental_start_at IS NULL) AND (invoice_item_id IS NULL))"

      add_index :cart_items, [:guest_cart_token, :listing_id, :variant_id],
        name: "index_cart_items_unique_guest_listing_variant",
        unique: true,
        where: "((guest_cart_token IS NOT NULL) AND (rental_start_at IS NULL))"
    end
  end
end
