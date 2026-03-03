class AddEndTimeStaggerIntervalToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :end_time_stagger_interval, :integer
  end
end
