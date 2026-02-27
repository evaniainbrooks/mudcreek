class AddOnDeleteNullifyToListingsLotForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :listings, :lots
    add_foreign_key :listings, :lots, on_delete: :nullify, validate: false
  end
end
