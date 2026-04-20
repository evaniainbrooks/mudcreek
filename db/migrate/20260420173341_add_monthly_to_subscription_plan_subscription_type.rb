class AddMonthlyToSubscriptionPlanSubscriptionType < ActiveRecord::Migration[8.1]
  def up
    safety_assured { execute "ALTER TYPE subscription_plan_kind ADD VALUE 'monthly'" }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
