class CreateFunctionNotifyBidEvent < ActiveRecord::Migration[8.1]
  def change
    create_function :notify_bid_event
  end
end
