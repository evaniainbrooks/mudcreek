class MakeOfferUserOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :offers, :user_id, true
  end
end
