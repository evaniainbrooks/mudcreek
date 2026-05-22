class CreateWorkOrderMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_milestones do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string  :name,              null: false
      t.integer :percentage,        null: false
      t.string  :trigger_state,     null: false
      t.integer :amount_cents,      null: false, default: 0
      t.boolean :invoice_generated, null: false, default: false
      t.integer :position,          null: false, default: 0
      t.timestamps
    end

    add_index :work_order_milestones, [ :work_order_id, :trigger_state ]
  end
end
