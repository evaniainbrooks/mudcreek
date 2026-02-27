class AddHashidToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :listings, :hashid, :string

    safety_assured do
      Listing.unscoped.find_each do |listing|
        loop do
          candidate = "#{SecureRandom.alphanumeric(8)}-#{listing.name.parameterize}"
          break listing.update_column(:hashid, candidate) unless Listing.unscoped.exists?(hashid: candidate)
        end
      end

      change_column_null :listings, :hashid, false
    end

    add_index :listings, :hashid, unique: true, algorithm: :concurrently
  end

  def down
    remove_column :listings, :hashid
  end
end
