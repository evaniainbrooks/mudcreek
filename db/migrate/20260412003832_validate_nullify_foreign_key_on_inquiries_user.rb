class ValidateNullifyForeignKeyOnInquiriesUser < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :inquiries, :users
  end
end
