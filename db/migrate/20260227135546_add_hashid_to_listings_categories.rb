class AddHashidToListingsCategories < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :listings_categories, :hashid, :string

    safety_assured do
      Listings::Category.unscoped.find_each do |category|
        loop do
          candidate = "#{SecureRandom.alphanumeric(8)}-#{category.name.parameterize}"
          break category.update_column(:hashid, candidate) unless Listings::Category.unscoped.exists?(hashid: candidate)
        end
      end

      change_column_null :listings_categories, :hashid, false
    end

    add_index :listings_categories, :hashid, unique: true, algorithm: :concurrently
  end

  def down
    remove_column :listings_categories, :hashid
  end
end
