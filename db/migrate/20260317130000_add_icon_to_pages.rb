class AddIconToPages < ActiveRecord::Migration[8.1]
  def change
    add_column :pages, :icon, :string
  end
end
