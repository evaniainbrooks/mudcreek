class CreateUsersVerifications < ActiveRecord::Migration[8.1]
  def change
    create_enum :user_verification_status, %w[not_validated validated]

    create_table :users_verifications do |t|
      t.references :tenant,       null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user,         null: false, foreign_key: true, index: false
      t.references :validated_by, foreign_key: { to_table: :users }, index: false
      t.enum :status, enum_type: :user_verification_status, default: "not_validated", null: false

      t.timestamps
    end

    add_index :users_verifications, :user_id,   unique: true
    add_index :users_verifications, :tenant_id
  end
end
