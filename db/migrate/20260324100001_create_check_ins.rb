class CreateCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_table :check_ins do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user,     null: false, foreign_key: true, index: false
      t.references :location, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :check_ins, [:user_id, :location_id]
    add_index :check_ins, [:location_id, :created_at]
  end
end
