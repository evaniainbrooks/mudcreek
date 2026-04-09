class CreateLedgers < ActiveRecord::Migration[8.1]
  def change
    create_table :ledgers do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :hashid, null: false
      t.text :description

      t.timestamps
    end

    add_index :ledgers, :hashid, unique: true
  end
end
