class AddBirthdateToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :birthdate, :date
  end
end
