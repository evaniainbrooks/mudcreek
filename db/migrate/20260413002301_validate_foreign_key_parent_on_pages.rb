class ValidateForeignKeyParentOnPages < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :pages, column: :parent_id
  end
end
