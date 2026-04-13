class FixForeignKeyOnDeleteForPageParentAndInquiryForm < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :pages, column: :parent_id
    add_foreign_key :pages, :pages, column: :parent_id, on_delete: :nullify, validate: false

    remove_foreign_key :pages, :inquiry_forms
    add_foreign_key :pages, :inquiry_forms, on_delete: :nullify, validate: false
  end
end
