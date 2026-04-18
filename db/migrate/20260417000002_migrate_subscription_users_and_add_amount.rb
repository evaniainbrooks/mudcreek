class MigrateSubscriptionUsersAndAddAmount < ActiveRecord::Migration[8.1]
  def up
    add_column :subscriptions, :amount_cents, :integer

    safety_assured do
      remove_index :subscriptions, name: "index_subscriptions_on_tenant_user_plan"
      remove_column :subscriptions, :user_id
    end
  end

  def down
    add_column :subscriptions, :user_id, :bigint

    safety_assured do
      add_index :subscriptions, [ :tenant_id, :user_id, :subscription_plan_id ],
        unique: true, name: "index_subscriptions_on_tenant_user_plan"
    end

    remove_column :subscriptions, :amount_cents
  end
end
