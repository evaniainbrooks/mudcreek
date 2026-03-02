class CreateAuctions < ActiveRecord::Migration[8.1]
  def change
    create_table :auctions do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string  :name,        null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :published,   null: false, default: false
      t.boolean :reconciled,  null: false, default: false
      t.timestamps
    end
  end
end
