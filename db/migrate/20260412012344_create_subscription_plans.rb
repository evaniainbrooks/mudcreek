class CreateSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    create_enum :subscription_plan_kind, %w[month_to_month]
    create_enum :subscription_status, %w[active lapsed cancelled]

    create_table :subscription_plans do |t|
      t.references :tenant,      null: false, foreign_key: true
      t.string  :name,           null: false
      t.text    :description
      t.integer :amount_cents,   null: false
      t.enum    :kind,           null: false, default: "month_to_month", enum_type: "subscription_plan_kind"

      t.timestamps
    end

    add_index :subscription_plans, [ :tenant_id, :name ], unique: true
  end
end
