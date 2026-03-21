class AddGuestFieldsToOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :offers, :guest_name, :string
    add_column :offers, :guest_email, :string
    add_column :offers, :guest_phone, :string
  end
end
