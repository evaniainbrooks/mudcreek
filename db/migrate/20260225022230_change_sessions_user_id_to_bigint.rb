class ChangeSessionsUserIdToBigint < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      remove_foreign_key :sessions, :users
      change_column :sessions, :user_id, :bigint
      add_foreign_key :sessions, :users
    end
  end

  def down
    safety_assured do
      remove_foreign_key :sessions, :users
      change_column :sessions, :user_id, :integer
      add_foreign_key :sessions, :users
    end
  end
end
