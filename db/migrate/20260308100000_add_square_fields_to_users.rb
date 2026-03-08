class AddSquareFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :square_customer_id, :string
    add_column :users, :default_square_card_id, :string
  end
end
