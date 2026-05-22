class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def up
    create_enum :work_order_state, %w[draft estimate_sent contracted in_progress completed cancelled]

    create_table :work_orders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user,   null: true,  foreign_key: true
      t.string  :number,    null: false
      t.string  :title,     null: false
      t.text    :description
      t.string  :client_name
      t.string  :client_email
      t.string  :client_phone
      t.integer :total_cents, null: false, default: 0
      t.enum    :state, null: false, default: "draft", enum_type: "work_order_state"
      t.string  :dropbox_sign_request_id
      t.datetime :estimate_sent_at
      t.datetime :contracted_at
      t.datetime :completed_at
      t.text :admin_notes
      t.timestamps
    end

    add_index :work_orders, :number, unique: true
    add_index :work_orders, [ :tenant_id, :state ]
  end

  def down
    drop_table :work_orders
    execute "DROP TYPE work_order_state"
  end
end
