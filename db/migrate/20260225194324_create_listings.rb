class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
