class CreateListingsAcquisitions < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_acquisitions do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :tenant,  null: false, foreign_key: true
      t.integer    :quantity,        null: false
      t.integer    :unit_price_cents
      t.date       :acquired_on,     null: false
      t.text       :notes
      t.timestamps
    end

    add_check_constraint :listings_acquisitions, "quantity > 0",
      name: "listings_acquisitions_quantity_positive"
  end
end
