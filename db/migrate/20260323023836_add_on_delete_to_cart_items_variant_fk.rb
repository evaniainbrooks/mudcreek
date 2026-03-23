class AddOnDeleteToCartItemsVariantFk < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :cart_items, column: :variant_id
    safety_assured do
      add_foreign_key :cart_items, :listings_variants, column: :variant_id, on_delete: :nullify
    end
  end
end
