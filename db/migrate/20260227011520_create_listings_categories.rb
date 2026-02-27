class CreateListingsCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
