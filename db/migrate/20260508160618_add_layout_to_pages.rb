class AddLayoutToPages < ActiveRecord::Migration[8.1]
  def change
    add_column :pages, :layout, :string
  end
end
