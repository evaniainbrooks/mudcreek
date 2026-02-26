class AddAcquisitionPriceCentsCheckConstraintToListings < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :listings, "acquisition_price_cents >= 0", name: "listings_acquisition_price_cents_non_negative", validate: false
  end
end
