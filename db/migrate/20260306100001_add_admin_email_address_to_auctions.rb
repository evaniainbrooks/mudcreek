class AddAdminEmailAddressToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :admin_email_address, :string
  end
end
