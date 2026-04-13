class AddParentIdToPages < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :pages, :parent, null: true, index: { algorithm: :concurrently }
  end
end
