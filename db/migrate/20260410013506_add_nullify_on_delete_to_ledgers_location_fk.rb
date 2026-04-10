class AddNullifyOnDeleteToLedgersLocationFk < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :ledgers, :locations if foreign_key_exists?(:ledgers, :locations)
    add_foreign_key :ledgers, :locations, on_delete: :nullify, validate: false
  end
end
