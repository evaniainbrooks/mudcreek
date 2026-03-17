class CreateUserCategoryInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :user_category_interests do |t|
      t.references :user,              null: false, foreign_key: true
      t.references :listings_category, null: false, foreign_key: { to_table: :listings_categories }
      t.references :tenant,            null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_category_interests, [:user_id, :listings_category_id], unique: true
  end
end
