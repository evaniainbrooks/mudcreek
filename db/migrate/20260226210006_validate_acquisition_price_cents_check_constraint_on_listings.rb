class ValidateAcquisitionPriceCentsCheckConstraintOnListings < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :listings, name: "listings_acquisition_price_cents_non_negative"
  end
end
