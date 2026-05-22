class CreateWorkOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_items do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string  :name,             null: false
      t.text    :description
      t.integer :quantity,         null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :position,         null: false, default: 0
      t.timestamps
    end
  end
end
