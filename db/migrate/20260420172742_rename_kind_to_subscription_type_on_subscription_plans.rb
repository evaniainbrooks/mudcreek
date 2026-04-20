class RenameKindToSubscriptionTypeOnSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    safety_assured { rename_column :subscription_plans, :kind, :subscription_type }
  end
end
