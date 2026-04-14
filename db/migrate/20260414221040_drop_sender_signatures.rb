class DropSenderSignatures < ActiveRecord::Migration[8.1]
  def up
    # Remove stale permissions that reference the now-deleted resource
    safety_assured { execute "DELETE FROM permissions WHERE resource = 'SenderSignature'" }
    drop_table :sender_signatures
  end

  def down
    create_table :sender_signatures do |t|
      t.references :tenant, null: false, foreign_key: true
      t.bigint :external_id, null: false
      t.string :name, null: false
      t.string :email_address, null: false
      t.boolean :confirmed, null: false, default: false
      t.boolean :dkim_verified, null: false, default: false
      t.boolean :spf_verified, null: false, default: false
      t.boolean :return_path_domain_verified, null: false, default: false

      t.timestamps
    end

    add_index :sender_signatures, [ :tenant_id, :external_id ], unique: true
  end
end
