class AddAffectsGalleryToListingsOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :listings_options, :affects_gallery, :boolean, null: false, default: false
  end
end
