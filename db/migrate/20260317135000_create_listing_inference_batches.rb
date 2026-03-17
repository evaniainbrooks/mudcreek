class CreateListingInferenceBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_inference_batches do |t|
      t.references :tenant,          null: false, foreign_key: true
      t.references :lot,             null: true,  foreign_key: true
      t.string     :hashid,          null: false
      t.string     :status,          null: false, default: "pending"
      t.integer    :total_count,     null: false, default: 0
      t.integer    :processed_count, null: false, default: 0
      t.integer    :failed_count,    null: false, default: 0
      t.text       :error_message
      t.timestamps null: false
    end
    add_index :listing_inference_batches, :hashid, unique: true
  end
end
