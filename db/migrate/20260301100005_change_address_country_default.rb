class ChangeAddressCountryDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :addresses, :country, from: "Canada", to: "CA"
  end
end
