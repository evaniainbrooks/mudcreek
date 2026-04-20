class AddKindsToSubscriptionPlanKind < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute "ALTER TYPE subscription_plan_kind ADD VALUE 'annual'"
      execute "ALTER TYPE subscription_plan_kind ADD VALUE 'semi_annual'"
      execute "ALTER TYPE subscription_plan_kind ADD VALUE 'one_time'"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
