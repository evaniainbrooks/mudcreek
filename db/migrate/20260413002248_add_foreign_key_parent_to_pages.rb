class AddForeignKeyParentToPages < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :pages, :pages, column: :parent_id, validate: false
  end
end
