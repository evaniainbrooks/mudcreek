class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :tenant,            null: false, foreign_key: true
      t.references :user,              null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.date  :renews_at,              null: false
      t.enum  :status,                 null: false, default: "active", enum_type: "subscription_status"

      t.timestamps
    end

    add_index :subscriptions, [ :tenant_id, :user_id, :subscription_plan_id ], unique: true,
      name: "index_subscriptions_on_tenant_user_plan"
  end
end
