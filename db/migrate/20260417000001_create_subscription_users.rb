class CreateSubscriptionUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_users do |t|
      t.references :tenant,       null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.boolean :primary_contact, null: false, default: false
      t.timestamps
    end

    add_index :subscription_users, [ :subscription_id, :user_id ],
      unique: true, name: "index_subscription_users_on_sub_and_user"
  end
end
