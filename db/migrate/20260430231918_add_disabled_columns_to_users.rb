class AddDisabledColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :disabled_email_address, :string
    add_column :users, :disabled_at, :datetime
  end
end
