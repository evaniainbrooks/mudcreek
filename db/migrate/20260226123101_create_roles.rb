class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :description, null: false

      t.timestamps
    end
  end
end
