class CreateBidIncrementSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :bid_increment_schedules do |t|
      t.bigint :tenant_id, null: false
      t.bigint :auction_id  # null = tenant default; set = auction override
      t.timestamps
    end

    add_index :bid_increment_schedules, :tenant_id
    add_index :bid_increment_schedules, :auction_id, unique: true
  end
end
