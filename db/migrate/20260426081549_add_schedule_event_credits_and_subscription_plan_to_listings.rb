class AddScheduleEventCreditsAndSubscriptionPlanToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :listings, :schedule_event_credits, :integer unless column_exists?(:listings, :schedule_event_credits)
    add_reference :listings, :subscription_plan, null: true, index: { algorithm: :concurrently }
    add_foreign_key :listings, :subscription_plans, validate: false
  end
end
