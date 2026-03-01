class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.bigint  :order_id,    null: false
      t.bigint  :listing_id               # nullable: listing may be deleted later
      t.string  :name,        null: false # snapshot
      t.integer :price_cents, null: false # snapshot of effective_price_cents
      t.string  :listing_type             # snapshot: "sale" or "rental"
      t.datetime :rental_start_at
      t.datetime :rental_end_at

      t.timestamps

      t.index :order_id
    end

    safety_assured do
      add_foreign_key :order_items, :orders
    end
  end
end
