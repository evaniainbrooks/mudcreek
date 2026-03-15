class AddHashidToLots < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :lots, :hashid, :string

    Lot.unscoped.find_each do |lot|
      loop do
        candidate = "#{SecureRandom.alphanumeric(8)}-#{lot.name.to_s.parameterize}"
        next if Lot.unscoped.exists?(hashid: candidate)
        Lot.unscoped.where(id: lot.id).update_all(hashid: candidate)
        break
      end
    end

    safety_assured do
      change_column_null :lots, :hashid, false
    end

    add_index :lots, :hashid, unique: true, algorithm: :concurrently
  end

  def down
    remove_column :lots, :hashid
  end
end
