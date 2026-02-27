class CreateLots < ActiveRecord::Migration[8.1]
  def change
    create_table :lots do |t|
      t.string :name, null: false
      t.string :number
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
