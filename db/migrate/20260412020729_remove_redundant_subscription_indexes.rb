class RemoveRedundantSubscriptionIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :subscription_plans, :tenant_id, name: "index_subscription_plans_on_tenant_id"
    remove_index :subscriptions, :tenant_id, name: "index_subscriptions_on_tenant_id"
  end
end
