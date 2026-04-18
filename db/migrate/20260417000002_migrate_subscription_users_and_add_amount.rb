class MigrateSubscriptionUsersAndAddAmount < ActiveRecord::Migration[8.1]
  def up
    # Seed subscription_users from existing user_id (as primary contact)
    safety_assured do
      execute <<~SQL
        INSERT INTO subscription_users (tenant_id, subscription_id, user_id, primary_contact, created_at, updated_at)
        SELECT tenant_id, id, user_id, true, NOW(), NOW()
        FROM subscriptions
        WHERE user_id IS NOT NULL
      SQL
    end

    add_column :subscriptions, :amount_cents, :integer

    # Backfill amount from the subscription plan
    safety_assured do
      execute <<~SQL
        UPDATE subscriptions s
        SET amount_cents = sp.amount_cents
        FROM subscription_plans sp
        WHERE s.subscription_plan_id = sp.id
      SQL
    end

    # Remove old unique index and the now-redundant user_id column
    safety_assured do
      remove_index :subscriptions, name: "index_subscriptions_on_tenant_user_plan"
      remove_column :subscriptions, :user_id
    end
  end

  def down
    add_column :subscriptions, :user_id, :bigint

    safety_assured do
      execute <<~SQL
        UPDATE subscriptions s
        SET user_id = su.user_id
        FROM subscription_users su
        WHERE su.subscription_id = s.id
          AND su.primary_contact = true
      SQL

      add_index :subscriptions, [ :tenant_id, :user_id, :subscription_plan_id ],
        unique: true, name: "index_subscriptions_on_tenant_user_plan"
    end

    remove_column :subscriptions, :amount_cents
  end
end
