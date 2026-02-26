class AddPublishedToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :published, :boolean, default: false, null: false
  end
end
