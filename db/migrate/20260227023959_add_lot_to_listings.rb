class AddLotToListings < ActiveRecord::Migration[8.1]
  def change
    safety_assured { add_reference :listings, :lot, null: true, foreign_key: true }
  end
end
