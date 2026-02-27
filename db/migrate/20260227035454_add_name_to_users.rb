class AddNameToUsers < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_column :users, :first_name, :string, null: false, default: ""
      add_column :users, :last_name, :string, null: false, default: ""
      change_column_default :users, :first_name, from: "", to: nil
      change_column_default :users, :last_name, from: "", to: nil
    end
  end
end
