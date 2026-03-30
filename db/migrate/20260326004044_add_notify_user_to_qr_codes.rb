class AddNotifyUserToQrCodes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :qr_codes, :notify_user, null: true, index: { algorithm: :concurrently }
    add_foreign_key :qr_codes, :users, column: :notify_user_id, validate: false
  end
end
