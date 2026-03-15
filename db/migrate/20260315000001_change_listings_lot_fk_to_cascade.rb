class ChangeListingsLotFkToCascade < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_foreign_key :listings, :lots
    add_foreign_key :listings, :lots, on_delete: :cascade, validate: false
    validate_foreign_key :listings, :lots
  end
end
