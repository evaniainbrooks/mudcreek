class AddListingForeignKeyToWidgets < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :widgets, :listings, column: :listing_id, on_delete: :cascade, validate: false
  end
end
