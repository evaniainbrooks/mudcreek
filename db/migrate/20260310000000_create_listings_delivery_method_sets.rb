class CreateListingsDeliveryMethodSets < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_delivery_method_sets do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false

      t.timestamps
    end
  end
end
