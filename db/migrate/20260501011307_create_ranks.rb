class CreateRanks < ActiveRecord::Migration[8.1]
  def change
    create_table :ranks do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :discipline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :ranks, [ :discipline_id, :name ], unique: true
  end
end
