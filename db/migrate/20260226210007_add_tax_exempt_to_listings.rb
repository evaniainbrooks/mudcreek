class AddTaxExemptToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :tax_exempt, :boolean, default: false, null: false
  end
end
