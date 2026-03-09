class CreateTriggerBidEventTriggerOnBids < ActiveRecord::Migration[8.1]
  def change
    create_trigger :bid_event_trigger_on_bids, on: :bids
  end
end
