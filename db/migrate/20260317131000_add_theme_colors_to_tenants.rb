class AddThemeColorsToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :primary_color,    :string
    add_column :tenants, :secondary_color,  :string
    add_column :tenants, :tertiary_color,   :string
    add_column :tenants, :background_color, :string
    add_column :tenants, :text_color,       :string
    add_column :tenants, :link_color,       :string
  end
end
