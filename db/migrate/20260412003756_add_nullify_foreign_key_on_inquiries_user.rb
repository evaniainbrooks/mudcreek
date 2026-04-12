class AddNullifyForeignKeyOnInquiriesUser < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :inquiries, :users
    add_foreign_key :inquiries, :users, on_delete: :nullify, validate: false
  end
end
