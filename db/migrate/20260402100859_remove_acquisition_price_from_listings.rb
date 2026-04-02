class RemoveAcquisitionPriceFromListings < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :listings, name: "listings_acquisition_price_cents_non_negative"
    safety_assured do
      remove_column :listings, :acquisition_price_cents
    end
  end

  def down
    add_column :listings, :acquisition_price_cents, :integer
    add_check_constraint :listings, "acquisition_price_cents >= 0",
      name: "listings_acquisition_price_cents_non_negative"
  end
end
