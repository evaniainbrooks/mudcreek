class ValidateFixForeignKeyOnDeleteForPageParentAndInquiryForm < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :pages, :pages, column: :parent_id
    validate_foreign_key :pages, :inquiry_forms
  end
end
