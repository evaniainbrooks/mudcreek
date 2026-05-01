class CreateRankAwards < ActiveRecord::Migration[8.1]
  def change
    create_table :rank_awards do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :rankable_type, null: false
      t.bigint :rankable_id, null: false
      t.references :rank, null: false, foreign_key: true
      t.integer :stripes, null: false, default: 0
      t.date :awarded_at, null: false
      t.references :awarded_by, foreign_key: { to_table: :users }, null: true
      t.text :notes

      t.timestamps
    end

    add_index :rank_awards, [ :rankable_type, :rankable_id ]
  end
end
