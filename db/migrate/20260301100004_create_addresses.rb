class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.bigint  :user_id,        null: false
      t.string  :street_address
      t.string  :city
      t.string  :province
      t.string  :postal_code
      t.string  :country,        default: "Canada"
      t.timestamps
      t.index :user_id, unique: true
    end

    safety_assured do
      add_foreign_key :addresses, :users
    end
  end
end
