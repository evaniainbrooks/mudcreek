class AddAcquisitionPriceCentsToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :acquisition_price_cents, :integer
  end
end
