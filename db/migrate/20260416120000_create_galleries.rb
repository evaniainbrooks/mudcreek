class CreateGalleries < ActiveRecord::Migration[8.1]
  def change
    create_table :galleries do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
