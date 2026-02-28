class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_enum :offer_state, %w[pending accepted declined]

    create_table :offers do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.references :tenant,  null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string  :message
      t.enum    :state, enum_type: :offer_state, default: "pending", null: false

      t.timestamps
    end

    add_check_constraint :offers, "amount_cents > 0", name: "offers_amount_cents_positive", validate: false
  end
end
