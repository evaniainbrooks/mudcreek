class ValidateOffersAmountCentsCheckConstraint < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :offers, name: "offers_amount_cents_positive"
  end
end
