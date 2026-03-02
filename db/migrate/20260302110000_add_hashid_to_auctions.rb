class AddHashidToAuctions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :auctions, :hashid, :string unless column_exists?(:auctions, :hashid)

    safety_assured do
      execute <<~SQL
        UPDATE auctions
        SET hashid = encode(sha256((id::text || name)::bytea), 'hex') || '-' || regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g')
        WHERE hashid IS NULL
      SQL

      change_column_null :auctions, :hashid, false
    end

    add_index :auctions, :hashid, unique: true, algorithm: :concurrently unless index_exists?(:auctions, :hashid)
  end

  def down
    remove_column :auctions, :hashid
  end
end
