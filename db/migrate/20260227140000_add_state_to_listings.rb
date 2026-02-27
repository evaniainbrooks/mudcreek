class AddStateToListings < ActiveRecord::Migration[8.1]
  def change
    create_enum :listing_state, %w[on_sale sold cancelled]
    add_column :listings, :state, :enum, enum_type: :listing_state, default: "on_sale", null: false
  end
end
