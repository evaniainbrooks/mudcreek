class AddActivatedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :activated_at, :datetime

    User.in_batches.update_all("activated_at = created_at")
  end
end
