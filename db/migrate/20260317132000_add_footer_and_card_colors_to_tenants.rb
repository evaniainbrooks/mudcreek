class AddFooterAndCardColorsToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :footer_color, :string
    add_column :tenants, :card_color,   :string
  end
end
