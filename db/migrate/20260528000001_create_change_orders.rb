class CreateChangeOrders < ActiveRecord::Migration[8.1]
  def up
    create_enum "change_order_status", [ "draft", "signature_sent", "signed" ]

    create_table :change_orders do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :tenant,     null: false, foreign_key: true
      t.string  :number,                    null: false
      t.text    :description,               null: false
      t.integer :amount_cents,  default: 0, null: false
      t.enum    :status, enum_type: "change_order_status", default: "draft", null: false
      t.string  :dropbox_sign_request_id
      t.datetime :signed_at

      t.timestamps
    end

    add_index :change_orders, :number, unique: true
  end

  def down
    drop_table :change_orders
    execute "DROP TYPE change_order_status"
  end
end
