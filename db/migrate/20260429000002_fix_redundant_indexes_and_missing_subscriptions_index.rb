class FixRedundantIndexesAndMissingSubscriptionsIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :user_locations, name: :index_user_locations_on_user_id
    remove_index :subscription_users, name: :index_subscription_users_on_subscription_id
    remove_index :schedule_event_sessions, name: :index_schedule_event_sessions_on_schedule_event_id
    remove_index :schedule_events, name: :index_schedule_events_on_schedule_id

    add_index :subscriptions, :tenant_id, algorithm: :concurrently
  end
end
