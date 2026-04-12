class AddNotificationDebounceSecondsToQrCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :qr_codes, :notification_debounce_seconds, :integer, default: 1800, null: false
  end
end
