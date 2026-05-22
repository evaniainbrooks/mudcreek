class AddWorkOrderMilestoneToInvoices < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :invoices, :work_order_milestone_id, :bigint unless column_exists?(:invoices, :work_order_milestone_id)
    add_index  :invoices, :work_order_milestone_id, algorithm: :concurrently unless index_exists?(:invoices, :work_order_milestone_id)
    unless foreign_key_exists?(:invoices, :work_order_milestones)
      add_foreign_key :invoices, :work_order_milestones, on_delete: :nullify, validate: false
    end
  end

  def down
    remove_foreign_key :invoices, :work_order_milestones if foreign_key_exists?(:invoices, :work_order_milestones)
    remove_index  :invoices, :work_order_milestone_id if index_exists?(:invoices, :work_order_milestone_id)
    remove_column :invoices, :work_order_milestone_id if column_exists?(:invoices, :work_order_milestone_id)
  end
end
