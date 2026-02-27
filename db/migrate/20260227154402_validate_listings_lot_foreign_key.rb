class ValidateListingsLotForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :listings, :lots
  end
end
