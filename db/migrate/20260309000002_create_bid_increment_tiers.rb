class CreateBidIncrementTiers < ActiveRecord::Migration[8.1]
  def change
    create_table :bid_increment_tiers do |t|
      t.bigint  :bid_increment_schedule_id, null: false
      t.integer :min_amount_cents, null: false, default: 0
      t.integer :increment_cents,  null: false
      t.timestamps
    end

    add_index :bid_increment_tiers, :bid_increment_schedule_id
  end
end
