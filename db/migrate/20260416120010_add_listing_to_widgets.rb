class AddListingToWidgets < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :widgets, :listing_id, :bigint
    add_index  :widgets, :listing_id, algorithm: :concurrently
  end
end
