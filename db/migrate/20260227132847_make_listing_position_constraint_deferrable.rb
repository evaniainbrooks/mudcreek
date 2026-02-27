class MakeListingPositionConstraintDeferrable < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      remove_index :listings, [ :tenant_id, :position ], if_exists: true
      execute <<~SQL
        ALTER TABLE listings
          ADD CONSTRAINT uq_listings_tenant_position
          UNIQUE (tenant_id, position)
          DEFERRABLE INITIALLY DEFERRED
      SQL
    end
  end

  def down
    safety_assured do
      execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS uq_listings_tenant_position"
      add_index :listings, [ :tenant_id, :position ], unique: true, algorithm: :concurrently
    end
  end
end
