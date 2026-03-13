class AddCommissionFieldsToLots < ActiveRecord::Migration[8.1]
  def change
    create_enum :lot_state, %w[submitted received auctioned settled paid]

    safety_assured do
      add_column :lots, :state, :enum,
        enum_type: :lot_state, default: "submitted", null: false
    end

    add_column :lots, :commission_rate,     :integer
    add_column :lots, :seller_fee_cents,    :integer
    add_column :lots, :payout_amount_cents, :integer
    add_column :lots, :settled_at,          :datetime
    add_column :lots, :paid_at,             :datetime
  end
end
