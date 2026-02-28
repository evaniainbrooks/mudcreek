class ValidateDiscountCodesAmountCentsCheckConstraint < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :discount_codes, name: "discount_codes_amount_cents_positive"
  end
end
