class AddForeignKeyInquiryFormToPages < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :pages, :inquiry_forms, validate: false
  end
end
