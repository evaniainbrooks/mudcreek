class BackfillListingPositionAndAddNotNull < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
      UPDATE listings
      SET position = sub.row_num
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY tenant_id ORDER BY id) AS row_num
        FROM listings
        WHERE position IS NULL
      ) sub
      WHERE listings.id = sub.id
      SQL
      change_column_null :listings, :position, false
    end
  end

  def down
    change_column_null :listings, :position, true
  end
end
