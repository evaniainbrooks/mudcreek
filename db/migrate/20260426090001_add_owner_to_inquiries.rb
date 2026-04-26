class AddOwnerToInquiries < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :inquiries, :owner, null: true, index: { algorithm: :concurrently }
    add_foreign_key :inquiries, :users, column: :owner_id, validate: false
  end
end
